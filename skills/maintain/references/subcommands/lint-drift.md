# Subcommand: `lint-drift` (new 2026-05)

Detect lint rules added but not yet applied across the codebase. Surface diff before any `--fix`.

## TodoWrite Items

```
- [ ] Detect lint config file(s) (rules/lint-drift.md)
- [ ] If none, surface skip; STOP
- [ ] Compute config diff vs git HEAD~N (default 30) — what rules changed?
- [ ] Run lint in report-only mode against full codebase
- [ ] Categorize findings: rule-was-added vs rule-was-tightened vs autofixable vs manual
- [ ] Present report grouped by rule
- [ ] For autofixable rules: offer --fix on a per-rule basis (not blanket)
- [ ] For manual rules: list affected files
- [ ] Never blanket-run --fix without per-rule user approval
```

## Supported Linters

Load `rules/lint-drift.md`:

| Language | Linter | Config files |
|---|---|---|
| TypeScript / JavaScript | ESLint | `.eslintrc.*`, `eslint.config.{js,mjs,ts}`, `package.json#eslintConfig` |
| TypeScript / JavaScript | Biome | `biome.json` |
| Python | ruff | `ruff.toml`, `pyproject.toml` |
| Python | flake8 | `.flake8`, `setup.cfg` |
| Ruby | RuboCop | `.rubocop.yml` |
| Rust | clippy | (configured via `Cargo.toml` lints sections or `clippy.toml`) |
| Go | golangci-lint | `.golangci.yml` |
| CSS | stylelint | `.stylelintrc.*` |

## Detection Algorithm

1. Read current lint config.
2. Compare against `git show HEAD~N:<config-path>` (default N=30; configurable).
3. Identify:
   - **rule-was-added** — new rule key in current config that wasn't there before.
   - **rule-was-tightened** — rule existed but severity raised (warn → error) or options narrowed.
   - **rule-was-loosened** — rule existed but severity lowered (informational; not flagged).
   - **rule-was-removed** — present in old, absent in current (informational; not flagged).
4. Run linter in report-only / dry-run / `--fix-dry-run` mode.
5. Categorize each violation:
   - **autofixable** — linter can fix automatically (`--fix`).
   - **manual** — requires code change.

## Output Format

```
Lint drift report — 3 rules added/tightened since HEAD~30:

▸ no-unused-vars (added)            42 violations across 18 files (autofixable: 28)
▸ prefer-const (tightened to error)  6 violations across 4 files  (autofixable: 6)
▸ react/jsx-key (added)             11 violations across 7 files  (manual)

Per-rule next steps:
  /maintain lint-drift --fix no-unused-vars
  /maintain lint-drift --fix prefer-const
  (no auto-fix offered for react/jsx-key — manual review required)
```

## --fix Strategy

`--fix` is **per-rule only**, never blanket:

```
/maintain lint-drift --fix <rule-id>
```

The skill:
1. Confirms with user: "Run `eslint --fix --rule <rule-id>` across {N} files?"
2. On approval, runs the fix.
3. Presents the diff for review.
4. Waits for user to approve commit.

**Never** run `eslint --fix` (without rule scoping) — it can introduce semantic changes from rules the user didn't intend to apply now.

## Type label

**Flexible** — lint-rule application is judgment-driven; some rules need consideration before applying.

## Pre-gate

- If no lint config exists: skip silently.
- If lint tool isn't installed: surface install command; do not proceed.

## Quality Gate

PASS:
- Drift surfaced in report.
- (If `--fix` was used) per-rule fix completed; remaining violations re-counted; diff presented.
- Lint exits 0 OR remaining violations are accepted by user.

FAIL:
- Blanket `--fix` ran without per-rule scoping.
- Diff not presented before commit.

## Verification §G (lives in rules/verification.md)

```
1. Re-read lint config.
2. Re-run linter on affected files.
3. Assert: previously-fixed rules now show 0 violations on those files.
4. Confirm: no unrelated rules newly violating (i.e., the --fix didn't introduce regressions).
```
