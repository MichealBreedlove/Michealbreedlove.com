# Sanitized Configuration Example

This snippet shows how secrets are automatically stripped before commit. The sanitize pipeline runs on every backup, catching 11 pattern types.

## Before Sanitization
```json
{
  "ollama": {
    "host": "10.1.1.21",
    "port": 11434,
    "api_key": "sk-proj-abc123def456ghi789jkl012mno345"
  },
  "openclaw": {
    "gateway": "10.1.1.10:18789",
    "token": "oc_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
  },
  "github": {
    "token": "ghp_1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r"
  }
}
```

## After Sanitization
```json
{
  "ollama": {
    "host": "10.1.1.21",
    "port": 11434,
    "api_key": "sk-REDACTED"
  },
  "openclaw": {
    "gateway": "10.1.1.10:18789",
    "token": "REDACTED"
  },
  "github": {
    "token": "ghp_REDACTED"
  }
}
```

## Patterns Detected (11 types)
1. `sk-*` (OpenAI-style API keys)
2. `ghp_*` (GitHub personal tokens)
3. `gho_*` (GitHub OAuth tokens)
4. `glpat-*` (GitLab tokens)
5. `Bearer *` (Auth headers)
6. `"token": "*"` (JSON token fields)
7. `"password": "*"` (JSON password fields)
8. `"apiKey": "*"` / `"api_key": "*"`
9. `-----BEGIN PRIVATE KEY-----`
10. Email addresses
11. Phone numbers

## CI Gate
GitHub Actions `verify-no-secrets.yml` runs on every push and **blocks the merge** if any pattern is detected in the diff.
