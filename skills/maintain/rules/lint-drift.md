# Rule: lint-drift

Detection rules for lint-config drift and per-rule fix strategies. Loaded by [`/maintain lint-drift`](../references/subcommands/lint-drift.md).

## Linter Detection

In order of preference (first hit wins):

| Language | Linter | Config files |
|---|---|---|
| TS/JS | Biome | `biome.json`, `biome.jsonc` |
| TS/JS | ESLint flat config | `eslint.config.{js,mjs,cjs,ts}` |
| TS/JS | ESLint legacy | `.eslintrc.{json,js,cjs,yaml,yml}`, `package.json#eslintConfig` |
| Python | Ruff | `ruff.toml`, `pyproject.toml#tool.ruff` |
| Python | flake8 | `.flake8`, `setup.cfg#flake8`, `tox.ini#flake8` |
| Ruby | RuboCop | `.rubocop.yml`, `.rubocop_todo.yml` |
| Rust | Clippy | `clippy.toml`, `.cargo/config.toml`, `Cargo.toml#lints` |
| Go | golangci-lint | `.golangci.yml`, `.golangci.toml`, `.golangci.json` |
| CSS | Stylelint | `.stylelintrc.{json,js,yml,yaml}`, `package.json#stylelint` |

## Drift-Detection Algorithm

```
1. Read current config (parse all relevant files).
2. Resolve rule set: collect all rules and their effective severity.
3. Read git history of config file: git log --oneline -n 30 -- <config>
4. For each commit that touched the config in the last 30 commits (or since last-sync-marker):
   a. Show diff for that commit.
   b. Identify added rules, removed rules, severity changes.
5. Aggregate: which rules are NEW or TIGHTENED compared to N commits ago.
6. For each new/tightened rule, run the linter to count current violations.
```

## Per-Linter Drift Detection

### ESLint

Compare two configs by:
1. Resolve flat-config or legacy to a normalized rule list.
2. For each rule: `(name, severity, options)`.
3. Diff: rules present in current but not in old, rules with different severity.

For `extends:` arrays: resolve transitively. A change from `eslint:recommended` to `eslint:strict` may add many rules.

### Biome

Parse `biome.json#linter.rules`. Recursive object structure (groups → rules). Diff per leaf rule.

### Ruff

Parse `[tool.ruff.lint]` selected/extend-select/ignore arrays. Diff sets.

## Rule Categories

For each new/tightened rule violation:

| Category | Definition | Auto-fix |
|---|---|---|
| `autofixable-safe` | Linter offers fix; rule is purely formatting/style (e.g., `quotes`, `semi`) | per-rule fix offered |
| `autofixable-semantic` | Linter offers fix; rule changes semantics (e.g., `prefer-const`, `no-var`) | per-rule fix offered with diff preview |
| `manual-trivial` | No auto-fix; trivial to fix (e.g., add missing prop) | offer to surface; user fixes manually |
| `manual-complex` | No auto-fix; non-trivial (e.g., `react/jsx-no-bind`, refactor required) | surface only |

## Per-Rule Fix Workflow

When user runs `/maintain lint-drift --fix <rule-id>`:

1. Confirm: "Run `<linter> --fix --rule <rule-id>` across {N} files?"
2. Run linter fix scoped to the single rule.
3. **Show diff** via `git diff` (don't just report file count).
4. Wait for user approval.
5. On approval, do nothing further (changes are already on disk; user commits via normal flow).
6. On rejection, run `git checkout -- <files>` to revert.

## Never

- Run blanket `--fix` (no rule scoping).
- Auto-commit lint fixes.
- Apply autofixable-semantic rules without showing the diff first.
- Modify the lint config itself (only modify code to comply with config).
