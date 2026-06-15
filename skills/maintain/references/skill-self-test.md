# Self-Test Scenarios

Pressure scenarios used to verify the skill behaves correctly under stress. Run these mentally (or against fixtures) when modifying the skill.

## Format

Each scenario lists:
- **Setup** — repo state to simulate
- **Invocation** — what the user types
- **Expected behavior** — what `/maintain` MUST do
- **Failure modes to watch** — past or hypothetical bugs to guard against

---

## Scenario 1: Merge Conflict in Progress

**Setup:** `git status` shows `Unmerged paths`. CLAUDE.md is one of the conflicted files.

**Invocation:** `/maintain sync`

**Expected behavior:**
1. Pre-gate detects merge in progress.
2. Skill ANNOUNCES: "Aborting `/maintain sync` — merge in progress. Resolve conflicts first."
3. **Does not** edit any file. **Does not** stage anything.
4. Suggests next step: resolve conflicts, then re-run.

**Failure modes:**
- Treating conflict markers (`<<<<<<<`) as ordinary content and "fixing" them.
- Running verification §A while CLAUDE.md is half-merged and reporting false GAPs.
- Auto-staging the conflicted file as part of "doc-only commit."

---

## Scenario 2: Monorepo with Multiple Lockfiles

**Setup:** Repo has `pnpm-workspace.yaml` plus a stray `package-lock.json` left from migration. Two of three workspaces are out of date.

**Invocation:** `/maintain locks`

**Expected behavior:**
1. Detects pnpm as primary (workspace config wins).
2. Flags the stray `package-lock.json` as `dual-lockfile` drift.
3. For each workspace: report drift between manifest and lockfile.
4. **Does not** auto-delete the stray lockfile. Surfaces it for user decision.
5. **Does not** run `pnpm install`. Recommends it explicitly.

**Failure modes:**
- Treating the npm lockfile as authoritative and reporting all pnpm workspaces as drifted.
- Auto-deleting the stray lockfile (irrecoverable in CI).
- Running `pnpm install --frozen-lockfile` and crashing on drift.

---

## Scenario 3: Release with No CHANGELOG

**Setup:** No `CHANGELOG.md`. `[Unreleased]` does not exist.

**Invocation:** `/maintain release v0.1.0`

**Expected behavior:**
1. Pre-gate detects missing CHANGELOG.md.
2. Offers to scaffold via `rules/changelog.md`.
3. If user accepts: scaffold an initial CHANGELOG.md with `[Unreleased]` containing entries inferred from git log.
4. Re-run `release` automatically OR suggest the user re-invoke. (Document either choice — default is to suggest re-invoke for clarity.)
5. **Never** silently skips and reports success.

**Failure modes:**
- Reporting "Done — released v0.1.0" without ever creating a CHANGELOG.
- Inferring entries from git log without showing the user first.

---

## Scenario 4: Repo with No Docs

**Setup:** Fresh repo with `package.json`, source files, but no CLAUDE.md, no README.md, no docs/.

**Invocation:** `/maintain` (full)

**Expected behavior:**
1. Phase 1A detects all artifacts missing.
2. Phase 1C freshness audit runs what it can and marks missing artifacts as `missing`, not `current`.
3. Phase 1D presents the freshness matrix and recommended actions.
4. Phase 1E presents the full scaffold checklist and waits for user selection.
5. If user selects "none": Phase 1F shows mostly unavailable steps (with `---` prefix and reason); skill DOES proceed but most steps are no-ops.
6. Skill records a warning artifact: "User declined all scaffolds. Most steps unavailable. Consider re-running with at least Root CLAUDE.md selected."

**Failure modes:**
- Bailing immediately ("nothing to maintain") without offering scaffolds.
- Silently scaffolding everything without asking (skipping the gate).
- Hanging because every Phase 2 step has missing artifacts.

---

## Scenario 4B: Docs Exist but Are Stale

**Setup:** Repo has CLAUDE.md, AGENTS.md, README.md, `.env.example`, and docs/spec. Recent commits added a new runtime env var and changed a service command, but the docs and `.env.example` were not updated. MEMORY.md is missing.

**Invocation:** `/maintain` (full)

**Expected behavior:**
1. Phase 1A detects the artifacts and the missing MEMORY.md.
2. Phase 1B selects a freshness range.
3. Phase 1C runs read-only checks before any scaffold prompt.
4. Phase 1D presents a freshness matrix:
   - Existing docs are `stale` or `unknown`, with evidence.
   - `.env.example` is `stale`, with the missing env var evidence.
   - MEMORY.md is `missing`, with optional scaffold recommendation.
5. Phase 1E offers MEMORY.md scaffold after the audit, not before.
6. Phase 1F pre-checks Env Sync and Sync Docs because evidence exists.

**Failure modes:**
- Reporting "Already present" for docs and stopping at a scaffold gate.
- Treating missing MEMORY.md as more important than stale existing docs.
- Pre-checking actions only because files exist, without evidence.
- Marking the full pass as PASS without a freshness matrix.

---

## Scenario 5: Repo with Only README.md

**Setup:** Repo has README.md only. Has source changes since last commit.

**Invocation:** `/maintain sync`

**Expected behavior:**
1. Pre-gate passes (≥ one doc file).
2. DIFF + MAP + ANALYZE consider only README.md as the target.
3. Verification §A relaxes the cross-doc consistency check (no other docs to cross-check against) and notes this in the report.
4. Sync completes. Suggests scaffolding CLAUDE.md as a follow-up.

**Failure modes:**
- Failing because CLAUDE.md doesn't exist.
- Cross-doc consistency check producing nonsense errors comparing README to itself.

---

## Scenario 6: Monorepo with Mixed Languages

**Setup:** Monorepo with `apps/web` (TypeScript), `services/api` (Python), `cli/` (Rust).

**Invocation:** `/maintain deadcode`

**Expected behavior:**
1. Convention detection identifies it as a monorepo with mixed languages.
2. For each workspace, run the appropriate dead-code tool:
   - apps/web → `knip` or `ts-prune`
   - services/api → `vulture`
   - cli → `cargo +nightly udeps` (or recognize Rust dead-code is harder; surface the limitation)
3. Aggregate results with workspace prefix.
4. Present per-workspace, never auto-delete.

**Failure modes:**
- Picking one tool and applying it to all (TypeScript dead-code tool on Python files = noise).
- Reporting Rust workspace as "no dead code found" when the tool wasn't actually run.

---

## Scenario 7: Watchlist Hit That Is a Legitimate Exception

**Setup:** `.claude/stale-watchlist.md` lists `process.env.MOCK_DB` as forbidden. The string appears in `tests/fixtures/README.md` as part of a documentation example explaining what was previously used.

**Invocation:** `/maintain sync`

**Expected behavior:**
1. Step 3.5 hits the pattern at `tests/fixtures/README.md:42`.
2. Skill records the hit in the GAP report with rule + reason.
3. **Does not** auto-edit. Step 4 PLAN presents the hit for user decision.
4. User responds "this one is intentional — documentation context." Skill respects that, marks as `OK-acknowledged`, and continues.
5. Optionally: skill suggests adding an inline-skip marker (e.g., `<!-- maintain:watchlist-skip -->`) so future runs don't re-flag.

**Failure modes:**
- Auto-removing the documentation example.
- Treating the hit as a test failure and aborting.

---

## RED → GREEN → REFACTOR Pattern

When adding a new subcommand or modifying behavior:

1. **RED** — write the scenario above WITHOUT the new code. Confirm the skill fails or behaves wrongly.
2. **GREEN** — add the rule/subcommand spec. Re-run mentally; confirm correct behavior.
3. **REFACTOR** — look for places the new code duplicates existing logic. Extract to shared rule or note in `rules/edit-patterns.md`.

## Adding New Scenarios

When a real-world failure happens:
1. Add a scenario here with the four sections.
2. Update [SKILL.md → Red Flags](../SKILL.md#red-flags--stop-and-reassess) if the failure deserves a tripwire.
3. Update [Rationalization Defense](../SKILL.md#rationalization-defense) if the failure was driven by reasoning Claude could have caught.
