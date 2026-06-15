# Subcommand: `sync`

Deep semantic doc sync. 6-step workflow: DIFF → MAP → ANALYZE → PLAN+EXECUTE → VERIFY → COMMIT.

## TodoWrite Items

```
- [ ] Step 1: DIFF — parse and categorize changes
- [ ] Step 2: MAP — match changes to doc sections
- [ ] Step 3: ANALYZE — find gaps (GAP/STALE/OK)
- [ ] Step 3.5: WATCHLIST SCAN (only if .claude/stale-watchlist.md exists; advisory only)
- [ ] Step 4: PLAN — present full plan; WAIT for user approval
- [ ] Step 4: EXECUTE — apply edits via Edit tool
- [ ] Step 5: VERIFY — verification.md §A
- [ ] Step 6: COMMIT — ask user; explicit-path stage; doc-only
```

## Input

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `range` | No | auto-detect (dirty → uncommitted; clean → HEAD; last-sync-marker if present) | git commit range |
| `scope` | No | repo root | directory to analyze |
| `docs` | No | auto-detect | doc files to update |

## Step 1: DIFF — Parse and categorize changes

Determine input mode:
- `--staged` flag → `git diff --staged`
- explicit range → `git diff <range>` and `git log --oneline <range>`
- dirty tree → `git diff`
- clean tree → `git show HEAD`

Load `rules/change-detection.md`. Categorize every change into typed entries:

| Change Type | What to look for |
|---|---|
| `env_var` | `.env.example` additions, `process.env.X`, Zod schema fields, `os.environ.get` |
| `config` | Config schema, defaults, validation |
| `function_sig` | New/modified parameters, return types |
| `new_file` | New paths in `git diff --stat` |
| `dependency` | `package.json` / `requirements.txt` / `Cargo.toml` changes |
| `test_count` | New test files, new `it()`/`test()`/`def test_*` |
| `security` | Rate limits, auth, validation rules |
| `phase_status` | Phase-completing modules |
| `bug_fix` | Fix commits, error handling corrections |
| `removal` | Deleted exports, removed files |
| `breaking` | Protocol/API surface changes |

Output: `{ type, file, line, description }[]`.

## Step 2: MAP — Match changes to doc sections

Load `rules/doc-targets.md`. Map each change to doc sections:

| Change Type | CLAUDE.md | README.md | MEMORY.md | .env.example | CHANGELOG.md |
|---|---|---|---|---|---|
| `env_var` | Env Vars table | Config table | Key Patterns | Comment + var | Changed |
| `config` | Env Vars / Security | Config table | Key Patterns | Default value | Changed |
| `function_sig` | — | — | Key function sigs | — | Changed |
| `new_file` | File Structure | Project Structure | Architecture | — | Added |
| `dependency` | Dependencies | — | — | — | Added |
| `test_count` | "N tests passing" | Test badge/count | Phase Status | — | — |
| `phase_status` | Phase table | Features | Phase Status | — | Added |
| `bug_fix` | — | — | Debugging notes | — | Fixed |
| `breaking` | Protocol/API | Migration notes | — | — | Changed |
| `removal` | File Structure | — | Architecture | — | Removed |
| `security` | Security Requirements | Security | — | — | Security |

Output: `{ change, targetFile, targetSection }[]`.

## Step 3: ANALYZE — Find gaps

Load `rules/gap-analysis.md`. For each (change, section) pair, classify:
- **GAP** — change exists in code, missing from docs
- **STALE** — docs reference old value, code has new value
- **OK** — already reflected

Output: gap report.

## Step 3.5: WATCHLIST SCAN — Forbidden-pattern tripwire (opt-in)

Load `rules/stale-watchlist.md`. If `.claude/stale-watchlist.md` exists, parse it and grep every detected doc target for each listed literal/regex pattern.

Append hits to the GAP report with:
- `file:line` location
- the watchlist rule that matched
- the rule's stated reason

If the file does not exist, skip silently.

**Do not auto-fix watchlist hits.** Surface for user decision. A pattern listed as forbidden in one context may be intentional in another.

## Step 4: PLAN + EXECUTE

Load `rules/edit-patterns.md`. For each gap:
1. Generate the specific edit (table row, count update, status change, new entry).
2. Present the full plan to the user for approval.
3. On approval, apply edits via Edit tool.

If `/technical-writing` is available, apply its prose rules.

## Step 5: VERIFY

Load `rules/verification.md` (§A). After edits:
1. Re-read each modified section.
2. Cross-check: every detected change appears in ≥1 doc.
3. Cross-doc consistency (env var in CLAUDE.md + README.md + .env.example).
4. Output final sync report.

**Pass:** zero unresolved GAP/STALE entries (or explicit user-accepted overrides).
**Fail:** any unresolved gap blocks Step 6.

## Step 6: COMMIT

Ask: "Commit these documentation updates?"

If approved:
1. Stage only modified doc files **by name** (never `git add .`).
2. Read `git log --oneline -5` for commit style.
3. Default message: `docs: sync documentation after [brief description]`.
4. Include updated file list in commit body.
5. Commit and show result.
6. Write `.claude/maintain/last-sync` marker.

## Quality Gate

PASS:
- Every detected change maps to ≥1 doc.
- Cross-doc consistency check passes.
- Watchlist hits all triaged.

FAIL:
- Unresolved GAPs after edit.
- Table structure broken.
- Cross-doc inconsistency unresolved.

Recovery: list unresolved gaps; offer to re-run on failed files.
