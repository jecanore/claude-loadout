# Academy — Self-test scenarios

**Loaded by:** `/skill-modernizer pressure-test`

These scenarios define the contract this skill must satisfy. Each scenario lists Setup / Invocation / Expected behavior / Failure modes. Add a scenario here whenever you fix a regression you want locked down.

---

## Scenario 1 — Full guide, happy path

**Setup:** A real project with `package.json` (name: `housingbase-app`), CLAUDE.md present, and at least one test file under `src/`. No existing `.academy/` directory.

**Invocation:** `/academy testing vitest-basics`

**Expected behavior:**
- Resolves project name to `Housingbase App` (or whatever package.json/CLAUDE.md yields).
- Creates `.academy/testing/` and writes `vitest-basics-guide.md`.
- Guide contains: Tech Stack Mastery callout, vocabulary table in Part 1, line-by-line annotated examples in Part 3 sourced from real test files, Prompting AI Agents section (Part 5), summary table, project-specific "What's next."
- Creates or updates `.academy/README.md`.
- Runs cross-reference step (glob is empty → no-op).

**Failure modes:**
- Generic examples used despite real test files existing → fail.
- Project name left as `{project}` literal anywhere → fail.
- Any banned puffery word in output → fail.
- Quality Checklist marked done without end-to-end re-read → fail.

---

## Scenario 2 — Explainer mode, single file

**Setup:** Project with `src/auth/login.ts` (~80 lines, mixed top-level functions and exports).

**Invocation:** `/academy explain src/auth/login.ts`

**Expected behavior:**
- Reads the full file (no truncation).
- Renders using `references/explainer-template.md`.
- Writes `.academy/explainers/login-explained.md`.
- Every code block has line-by-line explanation; no "obvious — skipped" lines.

**Failure modes:**
- File partially read (`limit:` set without justification) → fail.
- Output saved to wrong path (e.g., `.academy/auth/`) → fail.
- Sections of the file omitted from the walkthrough → fail.

---

## Scenario 3 — Audit mode, mixed-coverage project

**Setup:** Project with `package.json` listing `vitest`, `prisma`, `next`, `clerk`. `.academy/` exists with one guide: `.academy/basics/typescript-101-guide.md`. CLAUDE.md mentions Supabase migrations.

**Invocation:** `/academy audit`

**Expected behavior:**
- Detects tech stack: vitest, prisma, next, clerk, supabase (from CLAUDE.md).
- Inventories existing guides: 1 guide, 0 explainers.
- Emits Coverage Gaps table classifying each missing topic HIGH/MEDIUM/LOW with justification.
- Emits Suggested Learning Path ordered by dependency.

**Failure modes:**
- Declares `vitest` as covered because the typescript-101 guide mentions tests in passing → fail (must read vocabulary tables, not filename or substring).
- Suggests guides in arbitrary order without justifying the sequence → fail.
- Misses Supabase because it's only mentioned in CLAUDE.md, not `package.json` → fail.

---

## Scenario 4 — Refresh mode, partial drift

**Setup:** `.academy/security/auth-flows-guide.md` exists. Its Part 3 references `src/middleware.ts` (current on disk: signature changed since the guide was written) and `src/db/client.ts` (current on disk: unchanged).

**Invocation:** `/academy refresh security`

**Expected behavior:**
- Reads each Part 3 block with a `// <filepath>` comment.
- Diffs each against current file.
- Emits drift report marking middleware block STALE, db/client block CURRENT.
- **Pauses for user approval before any edit** (rigid gate).
- On approval: regenerates only the stale block + its line-by-line breakdown.
- Preserves Parts 1, 2, 5-9 unchanged.

**Failure modes:**
- Edits files before approval → fail (gate violation).
- Regenerates Parts 1, 2, or 5-9 wholesale → fail (preservation violation).
- Updates vocabulary table without justification (no new terms in refreshed code) → fail.

---

## Scenario 5 — Project resolution failure

**Setup:** Working directory is a fresh git init with no `package.json`, no `README.md`, no `CLAUDE.md`. Directory name is `tmp-scratch`.

**Invocation:** `/academy git branching`

**Expected behavior:**
- Project name resolution falls through to step 4 (directory name).
- Resolved name: `Tmp Scratch` (title-case of `tmp-scratch`).
- Guide is generated; every `{project}` reference shows `Tmp Scratch`.
- Skill does not fail or refuse — directory-name fallback is the documented contract.

**Failure modes:**
- Skill aborts with "no project found" → fail (fallback exists for a reason).
- Outputs literal `{project}` token → fail.
- Outputs empty / placeholder name → fail.

---

## Scenario 6 — Composition: skill invoked without `references/`

**Setup:** Skill has been partially deleted: `references/guide-template.md` is missing.

**Invocation:** `/academy testing vitest-basics`

**Expected behavior:**
- Skill detects the missing template file before generating Part 1.
- Surfaces a clear error naming the missing reference.
- Does not silently fall back to a fabricated template.
- Does not write a partial `.academy/...` file.

**Failure modes:**
- Generates a guide using guesswork in place of the template → fail.
- Writes a corrupt `.academy/testing/vitest-basics-guide.md` then errors → fail (must atomic-fail before writing).

---

## Adding scenarios

When fixing a regression in `academy`:

1. Reproduce the bug in a Setup block.
2. Document the correct Invocation.
3. State Expected behavior in present tense.
4. List Failure modes that previously triggered the bug.

Append the scenario at the bottom and renumber if needed. Pressure-test runs scenarios in order; the suite should fail fast on regressions.
