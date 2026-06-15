# Quality Gates

`/contribute check` runs all pre-submission quality gates. Every gate must pass (or be explicitly waived) before `/contribute submit` can proceed.

## Gate Execution Order

Run gates in this order — fail fast on blockers:

1. State validation (is setup complete?)
2. Tests pass
3. Lint passes
4. Contamination scan
5. Hardcoded count detection
6. Secrets scan
7. DCO/CLA compliance
8. New code has tests (warn)
9. Scope validation (warn)
10. Diff size check (warn)
11. License compatibility (new deps)
12. Commit count check (warn)

## Gate Details

### 1. State Validation

```bash
# Verify .contribute/state.json exists and has required fields
cat .contribute/state.json | jq '.upstream, .fork, .branch, .default_branch'
```

Required: `upstream`, `fork`, `branch`, `default_branch`, `conventions`.
If missing: "Run `/contribute setup` first."

### 2. Tests Pass

```bash
# Use detected test command from conventions
<conventions.test_command>
```

- If test command is null/unknown: warn "No test command detected. Skipping."
- Capture exit code. Non-zero → FAIL with output.
- Common commands: `npm test`, `yarn test`, `make test`, `cargo test`, `pytest`

### 3. Lint Passes

```bash
# Use detected lint command
<conventions.lint_command>
```

- If lint command is null: warn "No lint command detected. Skipping."
- Non-zero exit → FAIL with output.
- Auto-fix suggestion: "Run `<lint_command> --fix` to auto-fix, then re-check."

### 4. Contamination Scan

Run the full contamination scan algorithm (see `contamination-scan.md`).

- `critical` or `error` results → FAIL
- `warning` results → WARN, show to user, ask if intentional
- `info` results → note in output

### 5. Hardcoded Count Detection

Run the count detection algorithm (see `hardcoded-count-detection.md`).

- Any flagged assertions → FAIL with fix instructions
- Only triggers if files were added/removed

### 6. Secrets Scan

Scan all added lines for secret patterns:

```
# Patterns to detect
API_KEY\s*[=:]\s*["'][^"']+
SECRET\s*[=:]\s*["'][^"']+
TOKEN\s*[=:]\s*["'][^"']+
PASSWORD\s*[=:]\s*["'][^"']+
PRIVATE_KEY\s*[=:]\s*["'][^"']+
-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----
aws_access_key_id\s*=
aws_secret_access_key\s*=
```

Scan: `git diff upstream/<default>...HEAD` added lines only.
Skip: `.env.example`, `*.test.*`, test fixtures, documentation with placeholder values.
Any match → FAIL with file and line.

### 7. DCO/CLA Compliance

If `conventions.dco_required`:
```bash
# Check all commits have Signed-off-by
git log upstream/<default>..HEAD --format='%H %s' | while read hash msg; do
  if ! git log -1 --format='%B' $hash | grep -q "^Signed-off-by:"; then
    echo "FAIL: $hash missing Signed-off-by"
  fi
done
```

Fix instruction: `git commit --amend --signoff` or `git rebase --signoff upstream/<default>`

If `conventions.cla_required`:
- Warn: "This project requires a CLA. Verify you've signed it before submitting."
- Cannot be automatically verified — informational only.

### 8. New Code Has Tests (warn)

```bash
# Get changed source files (non-test)
git diff --name-only upstream/<default>...HEAD | grep -v test | grep -v spec | grep -v __tests__

# Check if any test files were also changed/added
git diff --name-only upstream/<default>...HEAD | grep -E '(test|spec|__tests__)'
```

If source files changed but no test files changed: WARN "No test changes detected. Consider adding tests for new code."

### 9. Scope Validation (warn)

```bash
# Count distinct top-level directories changed
git diff --name-only upstream/<default>...HEAD | cut -d/ -f1 | sort -u | wc -l
```

- 1-2 directories: OK
- 3+ unrelated directories: WARN "Changes span multiple concerns. Consider splitting into separate PRs."

Heuristic: directories are "related" if they share a common parent or follow a pattern (e.g., `src/` + `tests/` for the same module).

### 10. Diff Size Check (warn)

```bash
# Count added+removed lines (excluding lockfiles)
git diff upstream/<default>...HEAD --stat -- ':!package-lock.json' ':!yarn.lock' ':!pnpm-lock.yaml' | tail -1
```

- Under 300 lines: OK
- 300-500 lines: WARN "Large diff. Some maintainers prefer smaller PRs."
- Over 500 lines: HARD WARN "Very large diff. Strongly consider splitting."

### 11. License Compatibility

If `package.json` has new dependencies (compared to upstream):

```bash
# Get new deps
diff <(git show upstream/<default>:package.json | jq -r '.dependencies // {} | keys[]' | sort) \
     <(jq -r '.dependencies // {} | keys[]' package.json | sort) | grep "^>"
```

For each new dep:
```bash
npm view <pkg> license
```

Flag incompatible combinations:
- GPL dep added to MIT/Apache/BSD project → FAIL
- AGPL dep added to any non-AGPL project → FAIL
- Unknown license → WARN "Verify license compatibility manually"

### 12. Commit Count Check (warn)

```bash
git rev-list upstream/<default>..HEAD --count
```

- 1-3 commits: OK
- 4+ commits: WARN "Consider squashing to 1-3 logical commits. Run `git rebase -i upstream/<default>`"
- 1 commit with 500+ line diff: WARN "Large single commit. Consider splitting into logical commits."

## Output Format

```
## Quality Gate Results

| # | Gate | Status | Details |
|---|------|--------|---------|
| 1 | State validation | PASS | Setup complete for owner/repo |
| 2 | Tests | PASS | All 42 tests passed |
| 3 | Lint | PASS | No lint errors |
| 4 | Contamination | FAIL | 2 errors found (see below) |
| 5 | Count assertions | PASS | No hardcoded counts affected |
| 6 | Secrets | PASS | No secrets detected |
| 7 | DCO/CLA | SKIP | Not required |
| 8 | Test coverage | WARN | No test changes for new code |
| 9 | Scope | PASS | Single concern |
| 10 | Diff size | WARN | 342 lines changed |
| 11 | License compat | PASS | No new dependencies |
| 12 | Commit count | PASS | 2 commits |

### Blocking Issues (must fix)
[Details of any FAIL results]

### Warnings (review recommended)
[Details of any WARN results]

Result: BLOCKED — fix 1 issue before submitting.
```

## Gate Override

Users can bypass warnings with: `/contribute submit --force`

FAIL-level gates cannot be bypassed — they must be fixed. This prevents accidental contamination, secrets, and license violations from reaching upstream.
