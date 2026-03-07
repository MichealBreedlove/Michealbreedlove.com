# Proof Assets Index

Inventory of all artifacts in `/assets/proof/`. Used across portfolio case studies and proof pack.

## Screenshots (SVG placeholders — replace with real PNGs)

| File | Used on | Replace with | Redaction notes |
|---|---|---|---|
| `sre-dashboard.svg` | `case-study-sre-pipeline.html` (above Evidence section) | PNG screenshot of live SLO dashboard (budget bars, burn-rate table, incident feed) | Remove real hostnames, IPs, any auth tokens visible in UI. Blur or genericize node names if needed. |
| `gitops-report.svg` | `case-study-gitops-backups.html` (above Evidence section) | PNG screenshot of GitHub Actions CI run output showing secret scan pass | Remove repo URLs if private, blur commit SHAs if desired. Ensure no real secret patterns are visible in logs. |

### Replacement workflow

1. Take screenshot at ≥1600px wide (retina: 3200px).
2. Redact: blur/black-box any IPs, tokens, internal hostnames, email addresses.
3. Save as PNG, same filename minus `.svg` extension (e.g., `sre-dashboard.png`).
4. Update the `<img src=` in the corresponding HTML file.
5. Delete the `.svg` placeholder.

## Markdown artifacts (real, sanitized)

| File | Used on | Content | Redaction notes |
|---|---|---|---|
| `incident-timeline.md` | `proof.html` (Incident Timeline card) | Auto-generated timeline from a real SEV2 incident | IPs replaced with `10.x.x.x`, API keys replaced with `[REDACTED]` |
| `postmortem-example.md` | `proof.html` (Postmortem card) | Auto-generated postmortem with root cause, timeline, lessons, action items | Same as above |
| `sanitized-config.md` | `proof.html` (Secret Sanitization card) | Before/after showing secret stripping | Intentionally shows redaction patterns — no real secrets |
| `test-report.md` | `proof.html` (Test Report card) | Test suite output (all tests passing) | No sensitive data |
| `gitops-policy.md` | `proof.html` (GitOps Backup Policy card) | Backup schedule, retention, restore procedure | No sensitive data |
| `security-segmentation.md` | `proof.html` (Security Segmentation card) | VLAN architecture, firewall rules summary | IPs genericized, rule specifics abstracted |

## General redaction checklist

Before publishing any proof artifact:

- [ ] No real IP addresses (use `10.x.x.x` or `192.168.x.x`)
- [ ] No API keys, tokens, passwords, or SSH keys
- [ ] No email addresses or phone numbers
- [ ] No internal hostnames that reveal infrastructure beyond what's already public
- [ ] No private repo URLs
- [ ] File paths genericized (no `C:\Users\<realname>\` etc.)
