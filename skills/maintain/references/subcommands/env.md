# Subcommand: `env` (new 2026-05)

Sync `.env.example` against runtime environment-variable reads in code.

## TodoWrite Items

```
- [ ] Detect runtime env reads in code (process.env.X, os.environ.get, ENV[...])
- [ ] Read current .env.example (or offer to scaffold if missing)
- [ ] Compute set diff: code-vars vs example-vars
- [ ] Classify drift: missing-in-example, removed-in-code, name-changed
- [ ] Present plan to user (never auto-edit)
- [ ] On approval, update .env.example with new entries (preserve user comments)
- [ ] Verification §C: re-scan and confirm parity
- [ ] Offer doc-only commit
```

## Detection Patterns

Load `rules/env-sync.md`. Per language:

| Language | Patterns |
|---|---|
| TypeScript / JavaScript | `process.env.X`, `process.env["X"]`, Zod `env.parse({ X: ... })`, `import.meta.env.X` (Vite) |
| Python | `os.environ.get("X")`, `os.environ["X"]`, `os.getenv("X")`, Pydantic `BaseSettings` fields |
| Ruby | `ENV["X"]`, `ENV.fetch("X")` |
| Go | `os.Getenv("X")` |
| Rust | `std::env::var("X")` |
| PHP | `getenv("X")`, `$_ENV["X"]` |
| Shell scripts | `${X}`, `$X` (only when used near `: "${X:?}"` style guards) |

## Drift Classifications

- **missing-in-example** — code reads var X; `.env.example` doesn't list it.
- **removed-in-code** — `.env.example` lists var X; no runtime reads exist anywhere in code (excluding tests, archives, comments).
- **name-changed** — heuristic: similar var names with edit distance ≤ 2 across the two sets (e.g. `DATABASE_URL` in code vs `DB_URL` in example).

## Edit Strategy

When updating `.env.example`:
- **Preserve all user comments and section headers** (`# Authentication`, etc.).
- **Append missing-in-example vars** under a `# Auto-detected (review and re-categorize)` section, with default placeholder `YOUR_VALUE_HERE`.
- **Never auto-remove** vars classified as `removed-in-code`. They might be set in production via deploy config without an explicit code reference. Surface for user decision.
- **Never auto-merge** name-changed pairs. Surface candidate pairs and let user confirm.

## Pre-gate

- If `.env.example` is missing AND env reads exist in code: offer to scaffold a minimal `.env.example` from detected vars.
- If `.env.example` is missing AND no env reads detected: skip silently.

## Type label

**Flexible** — drift triage requires user judgment on what's a deploy-config var vs. a missed declaration.

## Quality Gate

PASS:
- Every detected runtime env read has a matching entry in `.env.example`.
- No `removed-in-code` entries auto-removed (only flagged).

FAIL:
- Reads exist with no `.env.example` entry AND user has not approved exclusion.

Recovery: re-run after user updates `.env.example`.

## Verification §C (lives in rules/verification.md)

```
1. Re-grep all detection patterns across code (excluding tests/archives).
2. Build set: code_vars.
3. Parse .env.example into set: example_vars.
4. Assert: code_vars ⊆ example_vars (or every difference is in user-approved-exclusions).
5. Report any name-changed candidates that remain unresolved.
```
