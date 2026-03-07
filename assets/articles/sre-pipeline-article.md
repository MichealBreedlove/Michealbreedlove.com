# Building an SRE Reliability Pipeline in a Homelab

Most homelab projects stop at "it works." This one adds SLOs, burn-rate alerting, incident management, and auto-generated postmortems — the same practices used at companies running production infrastructure at scale.

---

## Why reliability matters (even in a homelab)

"It's up" is not a reliability strategy. Services fail. Disks fill. Configs drift. Without measurement, you don't know if your systems are reliable — you just know they haven't broken yet.

SRE practices give you a framework to answer: *How reliable is this? Is it getting better or worse? When should I invest in fixing it?*

Applying this to a homelab also builds real skills. Employers hiring for SRE, platform, and DevSecOps roles want to see that you understand error budgets, incident response, and operational discipline — not just that you can spin up a VM.

## Architecture of the lab

The pipeline runs across a 4-node cluster:

- **Jasper** — GPU inference node (i9-13900K, RTX 4090, 64 GB). Runs Ollama for local LLM serving.
- **Nova** — Controller node (N305, 32 GB DDR5). Runs Ansible, the SRE pipeline, and storage.
- **Mira** — Utility compute (i7-2600K, 16 GB). Agent execution.
- **Orin** — Server workloads (Dell R630, Dual Xeon, 16 GB ECC).

All nodes run on Proxmox with OPNsense as the firewall and VLAN segmentation.

## Designing SLOs

The first step is deciding what "reliable" means for each service. I defined 6 SLOs:

| Service | Objective | Target |
|---|---|---|
| Gateway | Availability | 99.9% |
| Ollama Inference | Availability | 99.5% |
| Dashboard | Availability | 99.0% |
| Backup Freshness | Age < 24h | 100% |
| Agent Responsiveness | Latency < 30s | 99% |
| Node Health | Resource thresholds | 100% |

Each SLO is evaluated across 5 sliding time windows: 1h, 6h, 24h, 7d, and 30d. Short windows catch acute issues; longer windows reveal chronic degradation.

The error budget is the gap between the target and 100%. For a 99.9% SLO over 30 days, that's ~43 minutes of allowed downtime.

## Burn-rate alerting

Raw uptime percentages tell you what happened. Burn rate tells you what's *about to happen*.

- **< 1.0×** — Normal. Budget consumed slower than the window allows.
- **1.0× – 2.0×** — Warning. Budget will be exhausted before the window closes.
- **> 2.0×** — Critical. SLO breach likely. Safety gates activate.

This is the same approach Google describes in the *SRE Workbook*, adapted to homelab scale.

## Incident management workflow

When an SLO breaches or an anomaly is detected, the incident manager automatically:

1. Creates an incident with severity classification
2. Tracks the timeline — every state change logged with timestamps
3. Monitors resolution — TTR tracked from detection to close
4. Generates a postmortem — auto-created with timeline, root cause, and action items

Average TTR: **13 minutes**. Zero false positives.

## Safety gates

The gatekeeper prevents automated actions when the system is already degraded. If error budget is exhausted or incidents are unresolved, it blocks automation that could make things worse.

Same principle behind deployment freezes in production — don't push changes when you're already on fire.

## What I learned

1. **Start with 2-3 SLOs, not 20.** Pick the services that matter most.
2. **Error budgets change behavior.** You naturally prioritize reliability during burn spikes and features when budgets are healthy.
3. **Postmortems are the most valuable artifact.** Not for blame — for patterns.
4. **The safety gate paid for itself immediately.** Blocked an automated config change during degraded state within the first week.
5. **Testing matters more than you think.** 100+ acceptance tests catch regressions in the pipeline itself.

## Results

- 6 SLOs across 5 time windows
- 100+ acceptance tests
- 13-minute average TTR
- 0 false positives
- 0 credential leaks

---

**Go deeper:**
- Full case study: https://michealbreedlove.com/case-study-sre-pipeline.html
- Architecture: https://michealbreedlove.com/ai-cluster.html
- Starter kit (MIT): https://github.com/MichealBreedlove/homelab-sre-starter
- Portfolio: https://michealbreedlove.com
- GitHub: https://github.com/MichealBreedlove

---

*Tags: #sre #homelab #devops #reliability #security #infrastructure*
