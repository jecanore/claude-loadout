# Rule: secret-scan

Pattern + entropy detection for committed-looking secrets. Loaded by [`/maintain secrets`](../references/subcommands/secrets.md).

## Pattern Catalog

Patterns are organized by false-positive likelihood. Lower likelihood = stronger signal.

### LOW false-positive likelihood (high-confidence finds)

| Rule ID | Pattern | Notes |
|---|---|---|
| `aws-access-key` | `AKIA[0-9A-Z]{16}` | AWS-specific prefix |
| `aws-temp-token` | `ASIA[0-9A-Z]{16}` | AWS STS |
| `github-token` | `ghp_[A-Za-z0-9]{36}` | personal access |
| `github-oauth` | `gho_[A-Za-z0-9]{36}` | OAuth |
| `github-server-token` | `ghs_[A-Za-z0-9]{36}` | GitHub App server-to-server |
| `github-user-token` | `ghu_[A-Za-z0-9]{36}` | GitHub App user-to-server |
| `github-refresh` | `ghr_[A-Za-z0-9]{36}` | GitHub App refresh |
| `gitlab-pat` | `glpat-[A-Za-z0-9_-]{20}` | GitLab PAT |
| `slack-token` | `xox[abp]-[A-Za-z0-9-]{10,72}` | Slack tokens |
| `slack-webhook` | `https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+` | webhook |
| `stripe-live` | `sk_live_[A-Za-z0-9]{24,}` | Stripe live secret |
| `stripe-restricted` | `rk_live_[A-Za-z0-9]{24,}` | Stripe restricted live |
| `openai-key` | `sk-(?:proj-)?[A-Za-z0-9_-]{20,}` | OpenAI |
| `anthropic-key` | `sk-ant-(?:api|admin|sid)[0-9]{2}-[A-Za-z0-9_-]{20,}` | Anthropic |
| `private-key-pem` | `-----BEGIN (?:RSA \|EC \|DSA \|OPENSSH \|ENCRYPTED )?PRIVATE KEY-----` | PEM block |
| `ssh-private-key` | `-----BEGIN OPENSSH PRIVATE KEY-----` | OpenSSH |
| `pgp-private-key` | `-----BEGIN PGP PRIVATE KEY BLOCK-----` | PGP |

### MEDIUM false-positive likelihood

| Rule ID | Pattern | Why uncertain |
|---|---|---|
| `aws-secret-key` | `[A-Za-z0-9/+=]{40}` near `aws_secret`/`AWS_SECRET` | length-based; needs context keyword |
| `google-api-key` | `AIza[A-Za-z0-9_-]{35}` | Firebase web keys are technically public; flag with note |
| `jwt` | `eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{20,}` | sample/example JWTs are common in docs |
| `db-url-with-password` | `(?:postgres\|mysql\|mongodb\|redis)(?:\+srv)?://[^:]+:[^@]+@` | excluding `password`/`changeme`/`example` literals |
| `azure-storage-key` | `DefaultEndpointsProtocol=https;AccountName=[^;]+;AccountKey=[A-Za-z0-9+/=]{88}` | full connection string |
| `npm-token` | `npm_[A-Za-z0-9]{36}` | newer npm token format |
| `sentry-dsn` | `https://[a-f0-9]{32}@[a-z0-9.]+/\d+` | DSNs are intentionally public sometimes; flag |
| `twilio-key` | `SK[a-f0-9]{32}` | Twilio API |

### HIGH false-positive likelihood

| Rule ID | Pattern | Why noisy |
|---|---|---|
| `high-entropy-base64` | base64-ish strings ≥ 32 chars with shannon entropy ≥ 4.5 | random IDs, hashes, fixtures all match |
| `high-entropy-hex` | hex strings ≥ 32 chars | UUIDs, hashes, content addressing |
| `generic-api-key-keyword` | `(api[-_]?key|secret|token)["':\s=]+[A-Za-z0-9_-]{16,}` | catches lots of legitimate config |

Run HIGH-likelihood rules only when `--strict` is set; default scan is LOW + MEDIUM.

## Mandatory False-Positive Filters (always applied)

Skip without prompting:

- AWS-documented examples: `AKIAIOSFODNN7EXAMPLE`, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`.
- Common placeholders: `xxxxxxxxxx{20,}`, `<<<.*>>>`, `${...}`, `YOUR_*_HERE`, `REPLACE_ME`, `changeme`.
- Test fixture directories: `**/test/**`, `**/__tests__/**`, `**/fixtures/**`, `**/__fixtures__/**`.
- Files explicitly listed in `.claude/maintain/secret-allowlist.txt`.
- Strings inside fenced code blocks marked with `text` or `placeholder` language tag.

## Allowlist Format

`.claude/maintain/secret-allowlist.txt`:

```
# Format: <rule-id> <file-glob> [optional comment]
github-token  docs/examples/oauth-flow.md   # documented example flow
google-api-key  apps/web/src/firebase.ts    # public Firebase web key (acceptable per Firebase docs)
high-entropy-hex  test/**                    # ← redundant with mandatory filter, but explicit OK
```

## Entropy Calculation

For HIGH-likelihood rules:

```
shannon_entropy(s) = -sum(p_i * log2(p_i)) for each unique char's probability
```

Threshold ≥ 4.5 for base64-ish strings (good random has ~6.0 max).

## Output

Each finding:

```ts
{
  file: string;
  line: number;
  rule: string;             // rule ID from catalog above
  match: string;            // partially masked: first 4 + last 4 chars only
  context: string;          // 60 chars before + after for triage
  falsePositiveLikelihood: 'low' | 'medium' | 'high';
}
```

## Output Masking

When presenting findings to user, **always mask** the match:

```
✗ src/lib/auth.ts:42  github-token (LOW false-pos)
   ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   context: "const token = '[ghp_xxxx...xxxx]';"
```

Never echo the full secret to the user — even though they own the repo, the transcript may be shared.

## Never

- Auto-redact / auto-remove a hit.
- Echo the full match value (always mask).
- Run on git history (`git log -p`) without explicit user opt-in — that scan is high-volume and includes already-rotated secrets.
