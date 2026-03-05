# Test Report — SRE Pipeline

Run date: 2026-03-04
Runner: Nova (Ansible controller)

## P27 SLO Tests: 18/18 passed ✅

```
--- Config files ---
  ✅ slo_policy.json exists
  ✅ slo_catalog.json exists
--- Config validity ---
  ✅ slo_policy.json is valid JSON
  ✅ slo_catalog.json is valid JSON
--- Policy structure ---
  ✅ Policy has required fields
  ✅ Catalog has >=4 well-formed SLOs
--- Script files ---
  ✅ sli_sources.py exists
  ✅ sli_compute.py exists
  ✅ budget.py exists
  ✅ burn_rate.py exists
  ✅ slo_eval.py exists
  ✅ slo_render.py exists
  ✅ slo_publish.py exists
  ✅ slo_utils.py exists
--- Import tests ---
  ✅ All modules import cleanly
--- Burn rate math ---
  ✅ Burn rate calculations correct
--- Budget computation ---
  ✅ Budget computation correct
--- Secret scan ---
  ✅ No secrets in SLO code

P27 SLO Tests: 18/18 passed ✅
```

## P28 Incident Tests: 10/10 passed ✅

```
  ✅ Open creates JSON + latest pointer
  ✅ Note appends timeline event
  ✅ Close marks resolved + summary
  ✅ Incident markdown has required headings
  ✅ Postmortem has all required sections
  ✅ Tick opens incident on high burn SLO
  ✅ Tick handles gatekeeper deny
  ✅ Evidence paths contain no secrets
  ✅ All incidents have required JSON fields
  ✅ No secrets in incident code

P28 Incident Tests: 10/10 passed ✅
```

## P29 Portfolio Tests: 10/10 passed ✅

```
  ✅ portfolio_policy.json valid
  ✅ Redaction strips tokens + emails
  ✅ Site builds without errors
  ✅ index.md exists
  ✅ All 4 node pages exist
  ✅ All 3 Mermaid diagrams exist
  ✅ mkdocs.yml exists
  ✅ portfolio_pages.yml workflow exists
  ✅ All 8 pipeline pages exist
  ✅ No secrets in site output

P29 Portfolio Tests: 10/10 passed ✅
```

## Summary
| Suite | Passed | Total | Status |
|---|---|---|---|
| P27 SLO | 18 | 18 | ✅ |
| P28 Incident | 10 | 10 | ✅ |
| P29 Portfolio | 10 | 10 | ✅ |
| **Total** | **38** | **38** | **✅ 100%** |
