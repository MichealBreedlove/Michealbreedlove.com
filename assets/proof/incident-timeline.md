# Incident Timeline: INC-20260228-a3f7

**Title:** Ollama inference latency spike on Jasper
**Severity:** SEV2 — Minor
**Trigger:** SLO burn rate 3.2x in rolling_1h (threshold: 6x)
**Status:** ✅ Resolved

| Time (UTC) | Event | Detail | Actor |
|---|---|---|---|
| 2026-02-28 14:32 | `incident_opened` | Auto-opened by trigger: slo_high_burn | system |
| 2026-02-28 14:33 | `note` | Ollama response times >2s on Qwen 32B. Checking GPU utilization. | operator |
| 2026-02-28 14:35 | `note` | GPU at 98% — competing process (VS Code remote tunnel) consuming 3GB VRAM | operator |
| 2026-02-28 14:37 | `action` | Killed VS Code remote tunnel process. VRAM freed to 22GB available. | operator |
| 2026-02-28 14:39 | `note` | Inference latency back to <500ms. SLO burn rate dropping. | system |
| 2026-02-28 14:45 | `incident_closed` | Root cause: VRAM contention from dev tools. Fixed by process management. | operator |

**Duration:** 13 minutes
**Blast Radius:** Jasper (inference), all agents using Qwen 32B
**Resolution:** Killed competing GPU process, established VRAM reservation policy for Ollama.
