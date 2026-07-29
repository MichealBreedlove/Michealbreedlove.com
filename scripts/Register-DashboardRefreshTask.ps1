<#
.SYNOPSIS
    One-time setup: registers the weekly Task Scheduler job that runs
    Update-DashboardData.ps1 on Jasper.

.DESCRIPTION
    Creates (or replaces) a scheduled task named "Dashboard Data Refresh" that
    runs weekly as the current user. StartWhenAvailable is on, so if Jasper is
    off or asleep at the trigger time the task catches up at next boot — the
    Status page staleness banner trips at 21 days, so a missed week is safe.

    Also seeds %USERPROFILE%\.dashboard-refresh\config.json from the sample if
    no config exists yet.

    Run from an elevated or normal PowerShell prompt:
      powershell -ExecutionPolicy Bypass -File .\Register-DashboardRefreshTask.ps1

.NOTES
    The task runs only when the user is logged on (gh CLI auth is per-user and
    storing a password in the task is not worth it for a portfolio page).
    Change -DayOfWeek / -Time to taste.
#>

[CmdletBinding()]
param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'Update-DashboardData.ps1'),
    [System.DayOfWeek]$DayOfWeek = [System.DayOfWeek]::Monday,
    [string]$Time = '09:00',
    [string]$TaskName = 'Dashboard Data Refresh'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ScriptPath)) { throw "Refresh script not found: $ScriptPath" }
$ScriptPath = (Resolve-Path $ScriptPath).Path

# Seed local config from the sample if none exists.
$configDir  = Join-Path $env:USERPROFILE '.dashboard-refresh'
$configPath = Join-Path $configDir 'config.json'
$samplePath = Join-Path $PSScriptRoot 'dashboard-refresh.config.sample.json'
if (-not (Test-Path $configPath)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Copy-Item $samplePath $configPath
    Write-Host "Seeded config: $configPath — edit node hosts and cluster paths there."
} else {
    Write-Host "Config already present: $configPath"
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -MultipleInstances IgnoreNew

# Runs as the current logged-on user so gh CLI credentials are available.
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Registered task '$TaskName': every $DayOfWeek at $Time (catches up if the PC was off)."
Write-Host "Test it now with:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Logs land in:      $env:LOCALAPPDATA\DashboardRefresh\logs\"
