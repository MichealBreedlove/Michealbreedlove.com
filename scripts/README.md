# Dashboard Data Automation

Keeps `assets/cluster/dashboard-data.json` fresh so the Status page shows live
data instead of the "Archived Snapshot" banner (which trips when the snapshot
is more than 21 days old).

Runs on Jasper (Windows) weekly via Task Scheduler.

## Files

| File | Purpose |
|---|---|
| `Update-DashboardData.ps1` | Regenerates the snapshot from cluster state, then commits and ships it through the PR + squash-merge flow. |
| `Register-DashboardRefreshTask.ps1` | One-time setup: registers the weekly scheduled task and seeds the local config. |
| `dashboard-refresh.config.sample.json` | Config template. Copied to `%USERPROFILE%\.dashboard-refresh\config.json` — the live config stays **outside the repo** so internal hostnames/paths are never published and survive `git reset --hard`. |

## Setup (one time, on Jasper)

```powershell
cd C:\Users\mikej\Michealbreedlove.com\scripts
powershell -ExecutionPolicy Bypass -File .\Register-DashboardRefreshTask.ps1
notepad $env:USERPROFILE\.dashboard-refresh\config.json   # point hosts/paths at real cluster state
Start-ScheduledTask -TaskName 'Dashboard Data Refresh'    # smoke test
```

Then verify: PR merged on GitHub, and https://www.michealbreedlove.com/status.html
shows "snapshot from today" (allow a minute for Pages to deploy).

Dry run without shipping:

```powershell
powershell -ExecutionPolicy Bypass -File .\Update-DashboardData.ps1 -NoShip
git -C C:\Users\mikej\Michealbreedlove.com diff   # inspect, then...
git -C C:\Users\mikej\Michealbreedlove.com checkout -- assets/cluster/dashboard-data.json
```

## Config reference (`config.json`)

| Key | What it drives | If null / missing |
|---|---|---|
| `repo_path` | Local clone location | Defaults to `C:\Users\mikej\Michealbreedlove.com` |
| `nodes[].host` | Ping target per node (`localhost` = always Online) | — |
| `paths.queue_pending` | `queue.pending` = file count in dir | Carries forward previous value |
| `paths.queue_active` | `queue.active` = file count in dir | Carries forward previous value |
| `paths.queue_completed` | `queue.completed_24h` = files modified in last 24h | Carries forward previous value |
| `paths.knowledge_docs` | `knowledge.shared_documents` = `*.md` count (recursive) | Carries forward previous value |
| `paths.cluster_configs` | `knowledge.cluster_configs` = file count (recursive) | Carries forward previous value |
| `paths.dr_drill_marker` | `reliability.last_dr_drill` = file's last-write date | Carries forward previous value |

Always live regardless of config: `last_updated` (UTC, no suffix —
status.html appends `Z`), node statuses from ping, `nodes_online`,
`nodes_total`, `cluster_status` (Healthy / Degraded / Offline), and
`reliability.last_weekly_snapshot` (the run date — the weekly run *is* the
snapshot). `capabilities` and `orchestrator` flags carry forward from the
previous snapshot.

## How shipping works

main rejects direct pushes and merge commits are disabled repo-wide, so the
script follows the only allowed path:

1. `git fetch` + `checkout main` + `reset --hard origin/main` (never `pull` —
   squash merges make local history diverge)
2. Branch `dashboard-refresh-YYYYMMDD-HHmm`, commit, `git push -u` (4 retries,
   exponential backoff)
3. `gh pr create --base main --fill`
4. `gh pr merge --squash --delete-branch` (falls back to `--auto` if required
   checks are still running)
5. `checkout main` + `fetch` + `reset --hard origin/main`

Stale `index.lock` files (left by remote-session mounts) are removed
automatically before syncing if no git process is running.

## Troubleshooting

- **Logs**: `%LOCALAPPDATA%\DashboardRefresh\logs\` (newest 20 kept).
- **Task didn't run**: the task runs as the logged-on user (gh auth is
  per-user). `StartWhenAvailable` catches up after boot; a single missed week
  is still inside the 21-day staleness window.
- **Merge failed**: check `gh pr list` — an unmerged refresh PR can be
  squash-merged by hand; the next run starts clean either way.
- **Never commit secrets**: the live config never enters the repo; CI runs
  secret scanning on every push.
