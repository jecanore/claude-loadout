# Subcommand: `secrets` (new 2026-05)

Scan tracked files for committed-looking secrets. Surface for rotation; **never auto-redact**.

## TodoWrite Items

```
- [ ] Determine scope (default: all tracked files; opt-out via .gitignore + secret-allowlist)
- [ ] Run pattern detection (rules/secret-scan.md)
- [ ] Run entropy detection on suspected high-entropy strings in code/config
- [ ] Filter known false positives (test fixtures, well-known examples like AKIAIOSFODNN7EXAMPLE)
- [ ] Aggregate hits into state.secretHits with falsePositiveLikelihood
- [ ] Present report grouped by rule
- [ ] For each hit, ask user: rotate / move to .env / mark false positive / ignore
- [ ] Optionally write decisions to .claude/maintain/secret-allowlist.txt (NOT a secret store)
```

## Detection Categories

Load `rules/secret-scan.md`:

| Rule | Pattern | False-positive likelihood |
|---|---|---|
| `aws-access-key` | `AKIA[0-9A-Z]{16}` | low |
| `aws-secret-key` | `[A-Za-z0-9/+=]{40}` near `aws_secret`/`AWS_SECRET` keyword | medium |
| `github-token` | `ghp_[A-Za-z0-9]{36}`, `gho_*`, `ghs_*`, `ghu_*`, `ghr_*` | low |
| `gitlab-token` | `glpat-[A-Za-z0-9_-]{20}` | low |
| `slack-token` | `xox[abp]-[A-Za-z0-9-]+` | low |
| `stripe-key` | `sk_live_[A-Za-z0-9]{24,}`, `pk_live_*`, `rk_live_*` | low |
| `google-api-key` | `AIza[A-Za-z0-9_-]{35}` | medium (firebase web keys are technically public) |
| `openai-key` | `sk-[A-Za-z0-9]{20,}`, `sk-proj-[A-Za-z0-9]{20,}` | low |
| `anthropic-key` | `sk-ant-[A-Za-z0-9_-]{20,}` | low |
| `jwt` | three base64url segments separated by `.`, with `eyJ` start | medium (sample JWTs in docs are common) |
| `private-key-block` | `-----BEGIN (RSA \|EC \|OPENSSH )?PRIVATE KEY-----` | low |
| `db-url-with-password` | `postgres://user:password@`, `mysql://...`, `mongodb://...` (with non-empty password) | medium |
| `high-entropy-string` | 20+ char base64-ish or hex string in source/config | high (random IDs, hashes, fixtures) |

## False Positive Filters

Always filter these out automatically (no user prompt):
- `AKIAIOSFODNN7EXAMPLE` and other AWS-documented example keys
- `ghp_xxxxxxxxxxxxxxxxxxxx` and similar placeholder patterns
- Test fixtures in `**/test/**`, `**/__fixtures__/**`, `**/spec/**`
- Strings matching `<<<.*>>>` or `${...}` (template placeholders)
- Files explicitly listed in `.claude/maintain/secret-allowlist.txt`

## Edit Strategy — NEVER AUTO-REDACT

Auto-redaction has three failure modes:
1. **Loss of evidence** — the user may need the original to rotate the credential.
2. **False positive corruption** — redacting a hash or fixture breaks tests.
3. **Git history** — the secret is still in history; redacting in working tree creates false sense of safety.

**Always** surface the hit. Per hit, the user decides:
- **Rotate** — confirm decision; suggest steps (revoke at provider, replace with new credential, scrub history with `git filter-repo`).
- **Move to .env** — generate `.env` entry; replace the literal in code with `process.env.X` style read; update `.env.example`.
- **Mark false positive** — append to `.claude/maintain/secret-allowlist.txt` (path + rule).
- **Ignore for this run** — record in session state; do not modify files.

## Type label

**Rigid** for detection (must not miss real secrets); **never auto-fix**.

## Pre-gate

None — this is a defensive scan; runs in any state.

## Quality Gate

PASS:
- Every hit triaged with user decision.
- No new hits introduced by this run.

FAIL:
- A high-confidence hit (low false-positive likelihood) committed without triage.

## Verification §E (lives in rules/verification.md)

```
1. Re-run pattern detection on tracked files.
2. Subtract allowlist (.claude/maintain/secret-allowlist.txt).
3. Assert: every remaining hit was triaged this run.
4. If any hit remains untriaged AND high-confidence, BLOCK commit.
```
