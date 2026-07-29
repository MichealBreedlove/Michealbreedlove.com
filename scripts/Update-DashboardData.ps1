<#
.SYNOPSIS
    Regenerates assets/cluster/dashboard-data.json from live cluster state and
    ships it to michealbreedlove.com via the squash-merge PR flow.

.DESCRIPTION
    Designed to run unattended on Jasper (Windows) via Task Scheduler.

    Pipeline:
      1. Sync local clone to origin/main (handles stale index.lock).
      2. Probe each cluster node for reachability.
      3. Collect queue / knowledge metrics from configured paths, carrying
         forward the previous snapshot's values for anything unavailable —
         the script never publishes a broken or partial snapshot.
      4. Write the new snapshot (schema matches what status.html reads).
      5. Branch, commit, push, open a PR, squash-merge it, resync main.
         (main rejects direct pushes; squash merge is the only allowed path.)

    Configuration is read from %USERPROFILE%\.dashboard-refresh\config.json so
    internal hostnames and filesystem paths never enter the public repo and
    survive `git reset --hard`. See scripts/dashboard-refresh.config.sample.json.

.NOTES
    Compatible with Windows PowerShell 5.1 (Task Scheduler default).
    Requires: git, gh (authenticated as MichealBreedlove).
    Exit codes: 0 = shipped, 1 = fatal error (see log).
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $env:USERPROFILE '.dashboard-refresh\config.json'),
    # Regenerate the JSON but skip commit/PR/merge — for testing.
    [switch]$NoShip
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$logDir = Join-Path $env:LOCALAPPDATA 'DashboardRefresh\logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir ("refresh-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $logFile -Force | Out-Null

# Keep the newest 20 logs.
Get-ChildItem $logDir -Filter 'refresh-*.log' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 20 |
    Remove-Item -Force -ErrorAction SilentlyContinue

function Write-Step { param([string]$Message) Write-Host ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message) }

function Invoke-WithRetry {
    # Retries a script block up to $MaxAttempts with exponential backoff (2s, 4s, 8s, 16s).
    param(
        [scriptblock]$Action,
        [string]$What,
        [int]$MaxAttempts = 5
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            & $Action
            return
        } catch {
            if ($attempt -eq $MaxAttempts) { throw }
            $delay = [math]::Pow(2, $attempt)
            Write-Step ("{0} failed (attempt {1}/{2}): {3} — retrying in {4}s" -f $What, $attempt, $MaxAttempts, $_.Exception.Message, $delay)
            Start-Sleep -Seconds $delay
        }
    }
}

function Invoke-Git {
    # Runs git in the repo and throws on non-zero exit so $ErrorActionPreference applies.
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git -C $script:RepoPath @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') exited with code $LASTEXITCODE"
    }
}

try {
    # -----------------------------------------------------------------------
    # Config
    # -----------------------------------------------------------------------
    $defaults = @{
        repo_path  = 'C:\Users\mikej\Michealbreedlove.com'
        nodes      = @(
            @{ name = 'Jasper'; role = 'Coordinator & AI Inference';   host = 'localhost' },
            @{ name = 'Nova';   role = 'Automation & Monitoring';      host = 'nova' },
            @{ name = 'Mira';   role = 'Network Analysis & Auditing';  host = 'mira' },
            @{ name = 'Orin';   role = 'Deep Analysis & Validation';   host = 'orin' }
        )
        paths      = @{
            queue_pending   = $null
            queue_active    = $null
            queue_completed = $null
            knowledge_docs  = $null
            cluster_configs = $null
            dr_drill_marker = $null
        }
    }

    if (Test-Path $ConfigPath) {
        Write-Step "Loading config from $ConfigPath"
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } else {
        Write-Step "No config at $ConfigPath — using built-in defaults (metrics carry forward from previous snapshot)"
        $config = New-Object psobject
    }

    function Get-ConfigValue {
        param([string]$Name, $Default)
        $prop = $config.PSObject.Properties[$Name]
        if ($null -ne $prop -and $null -ne $prop.Value) { return $prop.Value }
        return $Default
    }

    $script:RepoPath = Get-ConfigValue 'repo_path' $defaults.repo_path
    $nodesConfig     = Get-ConfigValue 'nodes'     $defaults.nodes
    $pathsConfig     = Get-ConfigValue 'paths'     (New-Object psobject -Property $defaults.paths)

    function Get-ConfiguredPath {
        # Returns the configured path only if set and it exists on disk.
        param([string]$Name)
        $prop = $pathsConfig.PSObject.Properties[$Name]
        if ($null -eq $prop -or [string]::IsNullOrWhiteSpace($prop.Value)) { return $null }
        if (-not (Test-Path $prop.Value)) {
            Write-Step "WARNING: configured path '$Name' ($($prop.Value)) not found — carrying forward previous value"
            return $null
        }
        return $prop.Value
    }

    if (-not (Test-Path $script:RepoPath)) { throw "Repo path not found: $script:RepoPath" }
    $jsonRelPath = 'assets/cluster/dashboard-data.json'
    $jsonPath    = Join-Path $script:RepoPath 'assets\cluster\dashboard-data.json'

    # -----------------------------------------------------------------------
    # Sync repo to origin/main
    # -----------------------------------------------------------------------
    Write-Step "Syncing $script:RepoPath to origin/main"

    # A remote session's mount can leave a stale index.lock the session can't remove.
    $indexLock = Join-Path $script:RepoPath '.git\index.lock'
    if ((Test-Path $indexLock) -and -not (Get-Process git -ErrorAction SilentlyContinue)) {
        Write-Step "Removing stale index.lock"
        Remove-Item $indexLock -Force
    }

    Invoke-WithRetry -What 'git fetch' -Action { Invoke-Git fetch origin main }
    Invoke-Git checkout main
    # Never pull on main — squash merges make local history diverge; hard reset is the rule.
    Invoke-Git reset --hard origin/main

    # -----------------------------------------------------------------------
    # Previous snapshot (carry-forward baseline)
    # -----------------------------------------------------------------------
    if (-not (Test-Path $jsonPath)) { throw "Previous snapshot not found: $jsonPath" }
    $prev = Get-Content $jsonPath -Raw | ConvertFrom-Json

    # -----------------------------------------------------------------------
    # Probe nodes
    # -----------------------------------------------------------------------
    Write-Step "Probing cluster nodes"
    $nodes = @()
    foreach ($n in $nodesConfig) {
        if ($n.host -eq 'localhost' -or $n.host -eq $env:COMPUTERNAME) {
            $online = $true   # this script is running on it
        } else {
            $online = Test-Connection -ComputerName $n.host -Count 2 -Quiet -ErrorAction SilentlyContinue
        }
        $status = if ($online) { 'Online' } else { 'Offline' }
        Write-Step ("  {0} ({1}): {2}" -f $n.name, $n.host, $status)
        $nodes += [ordered]@{ name = $n.name; role = $n.role; status = $status }
    }
    $nodesOnline = @($nodes | Where-Object { $_.status -eq 'Online' }).Count
    $nodesTotal  = $nodes.Count
    $clusterStatus = if ($nodesOnline -eq $nodesTotal) { 'Healthy' }
                     elseif ($nodesOnline -gt 0)       { 'Degraded' }
                     else                              { 'Offline' }

    # -----------------------------------------------------------------------
    # Queue metrics (file-based durable job queue)
    # -----------------------------------------------------------------------
    function Get-FileCount {
        param([string]$Path, [datetime]$Since)
        $files = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
        if ($PSBoundParameters.ContainsKey('Since')) {
            $files = $files | Where-Object { $_.LastWriteTime -ge $Since }
        }
        return @($files).Count
    }

    $queuePending   = $prev.queue.pending
    $queueActive    = $prev.queue.active
    $queueCompleted = $prev.queue.completed_24h

    $p = Get-ConfiguredPath 'queue_pending'
    if ($p) { $queuePending = Get-FileCount -Path $p }
    $p = Get-ConfiguredPath 'queue_active'
    if ($p) { $queueActive = Get-FileCount -Path $p }
    $p = Get-ConfiguredPath 'queue_completed'
    if ($p) { $queueCompleted = Get-FileCount -Path $p -Since (Get-Date).AddHours(-24) }

    # -----------------------------------------------------------------------
    # Knowledge metrics (shared Markdown corpus + cluster configs)
    # -----------------------------------------------------------------------
    $sharedDocs     = $prev.knowledge.shared_documents
    $clusterConfigs = $prev.knowledge.cluster_configs

    $p = Get-ConfiguredPath 'knowledge_docs'
    if ($p) { $sharedDocs = @(Get-ChildItem -Path $p -Filter '*.md' -File -Recurse -ErrorAction SilentlyContinue).Count }
    $p = Get-ConfiguredPath 'cluster_configs'
    if ($p) { $clusterConfigs = @(Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue).Count }

    # -----------------------------------------------------------------------
    # Reliability
    # -----------------------------------------------------------------------
    # This scheduled run IS the weekly snapshot.
    $today = Get-Date -Format 'yyyy-MM-dd'
    $lastDrDrill = $prev.reliability.last_dr_drill
    $p = Get-ConfiguredPath 'dr_drill_marker'
    if ($p) { $lastDrDrill = (Get-Item $p).LastWriteTime.ToString('yyyy-MM-dd') }

    # -----------------------------------------------------------------------
    # Build snapshot — schema must match status.html exactly.
    # last_updated is UTC with no suffix: status.html appends 'Z' before parsing.
    # -----------------------------------------------------------------------
    $snapshot = [ordered]@{
        last_updated   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss')
        nodes          = $nodes
        nodes_online   = $nodesOnline
        nodes_total    = $nodesTotal
        cluster_status = $clusterStatus
        queue          = [ordered]@{
            pending       = [int]$queuePending
            active        = [int]$queueActive
            completed_24h = [int]$queueCompleted
        }
        knowledge      = [ordered]@{
            shared_documents = [int]$sharedDocs
            cluster_configs  = [int]$clusterConfigs
        }
        orchestrator   = [ordered]@{
            status                   = $prev.orchestrator.status
            adaptive_routing_enabled = [bool]$prev.orchestrator.adaptive_routing_enabled
            autonomous_tasks_enabled = [bool]$prev.orchestrator.autonomous_tasks_enabled
        }
        capabilities   = @($prev.capabilities)
        reliability    = [ordered]@{
            last_weekly_snapshot = $today
            last_dr_drill        = $lastDrDrill
            snapshots_active     = [bool]$prev.reliability.snapshots_active
            recovery_bundle      = [bool]$prev.reliability.recovery_bundle
        }
    }

    # PS 5.1 ConvertTo-Json escapes & < > ' as \uXXXX — undo for a clean diff.
    $json = $snapshot | ConvertTo-Json -Depth 6
    $json = $json -replace '\\u0026', '&' -replace '\\u003c', '<' -replace '\\u003e', '>' -replace '\\u0027', "'"
    $json = $json + "`n"
    [System.IO.File]::WriteAllText($jsonPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Step ("Snapshot written: {0}/{1} nodes online, cluster {2}" -f $nodesOnline, $nodesTotal, $clusterStatus)

    if ($NoShip) {
        Write-Step "-NoShip set — skipping commit/PR/merge. Repo left with local change."
        exit 0
    }

    # -----------------------------------------------------------------------
    # Ship: branch → commit → push → PR → squash merge → resync main
    # -----------------------------------------------------------------------
    $branch = "dashboard-refresh-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmm')
    Write-Step "Shipping on branch $branch"

    Invoke-Git checkout -b $branch
    Invoke-Git add -A
    Invoke-Git commit -m "chore: weekly cluster dashboard snapshot refresh ($today)"

    Invoke-WithRetry -What 'git push' -Action { Invoke-Git push -u origin $branch }

    & gh pr create --base main --fill --repo MichealBreedlove/Michealbreedlove.com
    if ($LASTEXITCODE -ne 0) { throw "gh pr create failed with code $LASTEXITCODE" }

    # Merge commits are disabled repo-wide; squash is the allowed path. Retry
    # briefly in case GitHub is still computing mergeability, then fall back to
    # auto-merge (fires once required checks pass).
    try {
        Invoke-WithRetry -What 'gh pr merge' -MaxAttempts 4 -Action {
            & gh pr merge $branch --squash --delete-branch --repo MichealBreedlove/Michealbreedlove.com
            if ($LASTEXITCODE -ne 0) { throw "gh pr merge exited with code $LASTEXITCODE" }
        }
    } catch {
        Write-Step "Direct merge failed — enabling auto-merge instead"
        & gh pr merge $branch --squash --delete-branch --auto --repo MichealBreedlove/Michealbreedlove.com
        if ($LASTEXITCODE -ne 0) { throw "gh pr merge --auto failed with code $LASTEXITCODE" }
    }

    # After a squash merge never pull — always hard reset onto origin/main.
    Invoke-Git checkout main
    Invoke-WithRetry -What 'git fetch' -Action { Invoke-Git fetch origin main }
    Invoke-Git reset --hard origin/main
    # Drop the local branch if gh's --delete-branch didn't (it can't while checked
    # out). EAP is relaxed first: with 'Stop', redirected native stderr throws.
    $ErrorActionPreference = 'Continue'
    & git -C $script:RepoPath branch -D $branch 2>$null
    $ErrorActionPreference = 'Stop'

    Write-Step "Done — snapshot shipped, main resynced."
    exit 0
} catch {
    Write-Step ("FATAL: {0}" -f $_.Exception.Message)
    # Best effort: leave the clone in a clean state for the next run.
    $ErrorActionPreference = 'Continue'
    try { & git -C $script:RepoPath checkout main 2>$null } catch { }
    try { & git -C $script:RepoPath reset --hard origin/main 2>$null } catch { }
    exit 1
} finally {
    Stop-Transcript | Out-Null
}
