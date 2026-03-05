# GitOps Backup Policy

## Overview
Every node in the cluster auto-commits its sanitized state to GitHub daily. This creates an auditable history of infrastructure changes, enables disaster recovery, and proves operational discipline.

## Schedule
| Node | Method | Frequency | Time |
|---|---|---|---|
| Jasper (Win11) | Scheduled Task | Daily | 02:30 AM |
| Nova (Ubuntu) | systemd timer | Daily + hourly sync | 02:30 AM + hourly |
| Mira (Ubuntu) | systemd timer | Daily + hourly sync | 02:30 AM + hourly |
| Orin (Ubuntu) | systemd timer | Daily + hourly sync | 02:30 AM + hourly |

## What Gets Backed Up
- System state: kernel, uptime, disk, memory, network, listening ports
- OpenClaw status: version, service state, node connectivity
- Enabled services list
- Configuration files (sanitized)

## What Never Gets Committed
- API keys, tokens, passwords (stripped by sanitize pipeline)
- SSH private keys (regenerate on restore)
- OpenClaw auth profiles (re-pair on restore)
- Session data, cookies, credentials

## CI Gate
`verify-no-secrets.yml` runs on every push:
- Scans for 11 secret patterns
- Checks for known sensitive filenames (.env, auth-profiles.json, etc.)
- **Blocks the merge** on any detection

## Restore Procedure
1. `git clone https://github.com/MichealBreedlove/Lab.git`
2. Navigate to `nodes/<hostname>/`
3. Follow `docs/runbooks/restore.md`
4. Re-pair OpenClaw nodes
5. Verify with `oc ping` and `oc health`

## Retention
- Git history: unlimited (GitHub)
- Daily snapshots: 30 days on-disk
- Weekly reports: 12 weeks on-disk
