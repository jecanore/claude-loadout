# Verification Rules

## Shared: Re-Read Modified Files

After all edits are applied, always start by re-reading each modified file:
- Confirm the edit was applied correctly (no malformed tables, broken trees, or garbled text)
- Check that surrounding content wasn't disturbed

This step is required for both sync and refs verification. Never skip it.

---

## Section A: Sync Verification

Use after the `sync` subcommand (doc gap analysis and synchronization).

### A1. Gap Coverage Check
- Walk the original change list from Step 1 (DIFF)
- For each change, confirm it now appears in at least one doc file
- If a change has no doc representation, flag it as an unresolved gap

### A2. Cross-Doc Consistency
When the same entity appears in multiple docs, ensure consistency:

| Entity | Must appear in |
|--------|---------------|
| Env var | CLAUDE.md env table + .env.example (at minimum) |
| Dependency | CLAUDE.md dependencies table |
| Test count | All locations that mention test count |
| Phase status | All locations that track phases |

### A3. Count Accuracy
If test counts were updated:
- Compare the number in docs against the test runner output (run `npm test 2>&1 | tail -5`)
- If they don't match, flag the discrepancy

### A4. No Orphaned References
- New sections shouldn't reference content that was deleted
- New table rows shouldn't reference columns that don't exist
- File structure entries should correspond to actual files

### A5. Structural Integrity
- Markdown tables have consistent column counts across all rows
- File structure trees have proper nesting characters
- Heading hierarchy is maintained (no H4 under H2 without H3)

### Sync Report Template

After verification, output:

```
## Sync Report

**Source:** [commit range or "uncommitted changes"]
**Changes detected:** N
**Gaps found:** N
**Edits applied:** N
**Files modified:** [list]

| Change | Type | Doc | Section | Status |
|--------|------|-----|---------|--------|
| THINKING_BUDGET_TOKENS | env_var | CLAUDE.md | Env Vars | Synced |
| THINKING_BUDGET_TOKENS | env_var | .env.example | — | Synced |
| handleChatSend thinking param | function_sig | MEMORY.md | LLM Notes | Synced |
| ... | ... | ... | ... | ... |

**Unresolved:** [any remaining gaps or issues]
```

---

## Section B: Refs Verification

Use after the `refs` subcommand (stale reference fixing).

### B1. Modified File Sweep

Grep all `old_patterns` across only the files modified in this session.

```
For each old_pattern:
  Grep pattern in [list of modified files]
  Expected: zero matches
```

**If matches remain:** The edit missed a reference. Go back to Execute and fix.

**Exception:** A match may be intentional if the old technology still exists in part of the system. Document these in the final report.

### B2. Repo-Wide Sweep

Grep all `old_patterns` across the entire repository (respecting `exclude` directories).

```
For each old_pattern:
  Grep pattern in [scope], excluding [exclude dirs]
  Record: file path, line number, match context
```

**Expected results:**
- Zero matches in Tier 1-3 files (AI context, onboarding, architecture)
- Possible matches in Tier 5 files (tests) if flagged but not yet fixed
- Possible matches in Tier 6 files only within the body text below disclaimer headers
- Possible matches in files that intentionally still use the old technology

**For each remaining match, classify as:**
- **Missed:** Should have been caught — go back and fix
- **Intentional:** The old technology genuinely still exists here — document with justification
- **False positive:** The pattern matched a non-stale usage (e.g., "mock" in "mockup") — ignore

### B3. Lint Check

Run the project's linter to catch broken imports or references.

```bash
npm run lint
# or the project's equivalent lint command from package.json
```

**Expected:** Same number of errors as before the changes (or fewer). The update should not introduce new lint errors.

### B4. Build Check (if applicable)

Run the build if source code comments (Tier 4) or config files were modified.

```bash
npm run build
# or the project's equivalent build command from package.json
```

**When to run:**
- Always if source code comments (Tier 4) were modified
- Always if config files were modified
- Skip if only markdown documentation was changed

### B5. Dev Server Smoke Test (optional)

Start the dev server and verify the application loads. Only if config files or environment-related documentation was modified.

### Refs Report Template

After all checks pass, output:

```
## Stale Reference Update Complete

**Migration:** [old technology] → [new technology]
**Date:** [YYYY-MM-DD]

### Files Modified ([N] total)

| Tier | Files Modified | Edits Made |
|------|---------------|------------|
| 1 (AI Context) | [N] | [M] |
| 2 (Onboarding) | [N] | [M] |
| 3 (Architecture) | [N] | [M] |
| 4 (Source Comments) | [N] | [M] |
| 5 (Tests) | [N flagged] | [M fixed / K deferred] |
| 6 (Historical) | [N] | [M disclaimer headers] |

### Remaining References

| File | Line | Match | Reason |
|------|------|-------|--------|
| ... | ... | ... | ... |

### Verification Results

- Modified file sweep: PASS (0 unexpected matches)
- Repo-wide sweep: PASS ([N] intentional matches documented)
- Lint: PASS ([N] pre-existing errors, 0 new)
- Build: PASS / SKIPPED
- Dev server: PASS / SKIPPED
```

---

## When to Skip

- If the user explicitly says "skip verification" or "just apply"
- For sync: if the only changes were CHANGELOG.md entries (low risk)
- For refs: if only Tier 6 disclaimer headers were added
- **Always do the re-read check (Shared step)** even when skipping other checks

## When Checks Fail

1. **Don't suppress the error.** Report it.
2. **Diagnose** whether the failure is from the update or pre-existing.
3. **Fix** if the failure is from the update (go back to Execute).
4. **Document** if the failure is pre-existing: "N pre-existing lint errors, 0 new from this change."
5. **Ask the user** if the fix requires a design decision (e.g., how to update a test).

---

## §C — Env Sync Verification

For [`/maintain env`](../references/subcommands/env.md):

1. Re-grep all detection patterns (rules/env-sync.md) across code, excluding tests/archives.
2. Build set: `code_vars`.
3. Parse `.env.example` into set: `example_vars`.
4. Assert: `code_vars ⊆ example_vars` OR every difference is in user-approved-exclusions for this run.
5. Report any `name-changed` candidates that remain unresolved.
6. PASS iff every detected runtime env read has a matching `.env.example` entry; FAIL otherwise.

---

## §D — Link Check Verification

For [`/maintain links`](../references/subcommands/links.md):

1. Re-parse all modified `.md` files for links.
2. Re-validate every link using rules/link-check.md.
3. Assert: no internal-broken links remain.
4. Report status of external links if user opted in.
5. PASS iff zero internal broken links; external link results informational only.

---

## §E — Secret Scan Verification

For [`/maintain secrets`](../references/subcommands/secrets.md):

1. Re-run pattern detection (rules/secret-scan.md) on tracked files.
2. Subtract allowlist (`.claude/maintain/secret-allowlist.txt`).
3. Assert: every remaining hit was triaged in this run (`state.secretHits[].decision` is set).
4. **BLOCK** any commit if a high-confidence (LOW false-positive) hit remains untriaged.
5. PASS iff every hit has a recorded decision (rotate / move-to-env / mark-fp / ignore).

---

## §F — Dead Code Verification

For [`/maintain deadcode`](../references/subcommands/deadcode.md):

1. Re-run dead-code tool with same flags.
2. Assert: any high-confidence finding from the previous run is either:
   a. gone (deleted this run), OR
   b. listed in `.claude/maintain/deadcode-allowlist.txt`.
3. Run lint; must pass.
4. Run build (or test if no build); must pass.
5. PASS iff lint and build both pass AND no high-confidence finding is unaccounted for.
6. **REVERT** any deletions that caused lint/build failure before reporting.

---

## §G — Lint Drift Verification

For [`/maintain lint-drift`](../references/subcommands/lint-drift.md):

1. Re-read lint config.
2. Re-run linter on the affected files (the files modified by `--fix`).
3. Assert: previously-fixed rules now show 0 violations on those files.
4. Confirm: no unrelated rules newly violating (the `--fix` should not have introduced regressions).
5. PASS iff (3) and (4) both hold; FAIL otherwise.

---

## Cross-Subcommand Verification (composed runs)

When `full` runs multiple subcommands, run each subcommand's verification section after that subcommand completes. The `full` quality gate PASSes only if every selected subcommand's individual verification passes.
