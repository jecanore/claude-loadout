# Self-test scenarios for `skill-modernizer`

**Loaded by:** `pressure-test` (when targeting this skill); manual reference for contributors

**Purpose:** RED/GREEN/REFACTOR acceptance suite for `skill-modernizer` itself. Each scenario describes setup, invocation, expected behavior, and failure modes. Run via `/skill-modernizer pressure-test <path-to-this-skill>`.

---

## Format

Each scenario has these fields:

- **Color:** `RED` (must-pass) or `GREEN` (advisory)
- **Setup:** how to prepare the environment
- **Invocation:** exact command to run
- **Expected behavior:** what success looks like
- **Failure modes:** how this scenario fails (so the test can decide PASS / FAIL / SKIP)

---

## Scenarios

### 1. Auditing a fully unmodernized skill

**Color:** RED

**Setup:** Create a temporary skill at `<tmp>/test-unmodernized/SKILL.md` with only frontmatter (`name`, `description`, no version, no decision graph, no Red Flags, no Rationalization Defense, no self-test). Body is a single paragraph.

**Invocation:** `/skill-modernizer audit <tmp>/test-unmodernized/`

**Expected behavior:**
- Audit completes without crashing.
- Report shows `0/10` to `2/10` patterns present.
- Overall grade is `F`.
- Suggested fixes section is non-empty.
- Report does not crash on missing sections.

**Failure modes:**
- FAIL: audit crashes or emits an empty report.
- FAIL: grade is anything above `D` for a fully empty skill.

---

### 2. Auditing a partially modernized skill

**Color:** RED

**Setup:** Create a skill with 9 patterns present and 1 deliberately weak (e.g., Red Flags section exists but contains only 2 items, below the threshold of 4).

**Invocation:** `/skill-modernizer audit <tmp>/test-partial/`

**Expected behavior:**
- Patterns 1-8, 10 report `present`.
- Pattern 2 (Red Flags) reports `partial` with note explaining the threshold.
- Grade is `B` (one weak pattern weighted high but most are present).
- Suggested fixes points to extending Red Flags.

**Failure modes:**
- FAIL: Pattern 2 reports `present` despite being below threshold.
- FAIL: Grade is `A` despite weak pattern.

---

### 3. Modernizing a skill mid-conversion

**Color:** RED

**Setup:** Create a skill that has a half-finished `references/` directory — e.g., `references/subcommands/audit.md` exists but is empty; `references/skill-self-test.md` exists with one scenario (below threshold of 5).

**Invocation:** `/skill-modernizer modernize <tmp>/test-half-done/`

**Expected behavior:**
- Audit identifies the half-finished state.
- Modernize plans edits that complete (not duplicate or replace) the existing files.
- Diff preview shows additions, not regressions.
- After user approval, post-apply audit improves the grade.
- Existing partial content is preserved.

**Failure modes:**
- FAIL: Modernize overwrites existing partial content silently.
- FAIL: Diff shows deletions of partial content without explicit user gate.
- FAIL: Post-apply audit grade is lower than pre-apply.

---

### 4. Creating with conflicting names

**Color:** RED

**Setup:** A skill named `existing-skill` already exists in the user's skills directory.

**Invocation:** `/skill-modernizer create existing-skill`

**Expected behavior:**
- Pre-gate detects collision.
- Skill warns and offers alternatives (e.g., `existing-skill-v2`, `existing-skill-2`, `existing-skill-new`).
- Skill does NOT overwrite without explicit `--overwrite` flag and user approval.
- With `--overwrite`, a backup is created before overwrite.

**Failure modes:**
- FAIL: Existing skill is overwritten without warning.
- FAIL: Pre-gate doesn't detect the collision.

---

### 5. Pressure-test without `superpowers:writing-skills`

**Color:** RED

**Setup:** `superpowers:writing-skills` is not installed (or temporarily renamed away).

**Invocation:** `/skill-modernizer pressure-test <path-to-some-skill>`

**Expected behavior:**
- Composer detection finds the absence.
- Skill offers three options: install, abort, reduced-rigor.
- On `r` (reduced-rigor): scenarios run; report contains a banner indicating reduced-rigor mode; the TDD Iron Law scenario is `SKIP` with reason `"writing-skills not installed; reduced-rigor mode"`.
- On `n`: subcommand aborts cleanly without partial state.

**Failure modes:**
- FAIL: Skill auto-installs without user approval.
- FAIL: Reduced-rigor mode hides the banner.
- FAIL: Report claims overall PASS while a RED scenario was SKIP.

---

### 6. Migrate a legacy 800-line monolithic SKILL.md

**Color:** RED

**Setup:** A skill with `SKILL.md` of ~800 lines, no `references/` directory, all content embedded inline (subcommand handlers, examples, long-form prose).

**Invocation:** `/skill-modernizer migrate <tmp>/test-monolith/`

**Expected behavior:**
- Detect identifies legacy markers (line count > 500, no `references/`, missing `version:`).
- Plan extracts long sections into `references/` files per `rules/migration-map.md`.
- Diff preview shows all extractions; line count totals match (no content lost).
- Post-apply: SKILL.md is shorter; `references/` files exist; total lines preserved.
- Version bumped to major (`0.x.y → 1.0.0`).

**Failure modes:**
- FAIL: `lines_lost > 0` in the JSON output.
- FAIL: Any section is dropped silently.
- FAIL: Version bump is minor instead of major.

---

### 7. Audit a `reference-only` archetype skill

**Color:** RED

**Setup:** A skill with `archetype: reference-only` in frontmatter; SKILL.md is short and informational; no decision graph; no self-test; no `references/` directory.

**Invocation:** `/skill-modernizer audit <tmp>/test-reference-only/`

**Expected behavior:**
- Patterns 1 (Decision graph), 4 (TodoWrite), 6 (Rigid/Flexible), 7 (allowed-tools), 8 (references/), 9 (Self-test) report `n/a` per archetype weighting.
- Grade is computed only from patterns that apply.
- Grade is `A` if Red Flags and Rationalization (the patterns that DO apply) are present.

**Failure modes:**
- FAIL: Grade is not `A` despite all applicable patterns being present.
- FAIL: Decision graph missing causes grade to drop.

---

### 8. `audit-all` with 50 skills

**Color:** RED

**Setup:** A directory with 50 skills (mix of grades).

**Invocation:** `/skill-modernizer audit-all <tmp>/test-bulk/`

**Expected behavior:**
- Parallel dispatch happens (10 concurrent agents by default).
- Run completes in roughly the time of one batch (not 50 sequential audits).
- Aggregated report includes all 50 skills.
- One intentionally-failed agent batch (simulate by deleting a SKILL.md mid-run) is reported as `unknown` for those skills, not silently dropped.
- Run does not fail overall when one batch fails.

**Failure modes:**
- FAIL: Skills disappear from report.
- FAIL: Single agent failure causes overall run failure.
- FAIL: Run executes serially.

---

### 9. `refresh` with conflicting findings

**Color:** RED

**Setup:** Mock the research source list so two sources return contradictory claims about a pattern (e.g., source A says pattern X is required, source B says it's deprecated).

**Invocation:** `/skill-modernizer refresh`

**Expected behavior:**
- Both findings appear in the proposed diff.
- A `conflicts` section in the report explicitly lists the conflict.
- The skill does NOT pick arbitrarily — the user is asked to resolve.
- On user resolution, the chosen finding is applied; the rejected finding is logged in audit history.

**Failure modes:**
- FAIL: Refresh silently picks one source's finding.
- FAIL: Conflict is hidden from the report.

---

### 10. Backup retention pruning

**Color:** RED

**Setup:** Fabricate 5 backups for one skill across 35 days (some > 30 days old, some unverified).

**Invocation:** `/skill-modernizer prune-backups`

**Expected behavior:**
- Last 3 verified backups within 30-day TTL are kept.
- Backups > 30 days old are pruned regardless of count.
- Unverified backups within 7-day extra grace are kept.
- Index JSONL is updated (append-only — old entries marked as pruned in a new line).

**Failure modes:**
- FAIL: All 5 backups remain.
- FAIL: Verified backup younger than 30 days is pruned.
- FAIL: Index JSONL entries are mutated (rather than appended).

---

### 11. Self-audit (eat own dog food)

**Color:** RED

**Setup:** This skill, as installed.

**Invocation:** `/skill-modernizer audit <path-to-skill-modernizer>`

**Expected behavior:**
- All 10 patterns report `present`.
- Grade is `A`.
- No suggested fixes.

**Failure modes:**
- FAIL: Any pattern reports anything other than `present` (or `n/a` for archetype reasons; this skill is `orchestrator-with-subcommands`, so all 10 should apply).
- FAIL: Grade is below `A`.

---

### 12. Plugin-cache target

**Color:** RED

**Setup:** A skill installed via plugin, located inside `<config>/plugins/cache/...`.

**Invocation:** `/skill-modernizer modernize <plugin-cache-skill-path>`

**Expected behavior:**
- Pre-gate detects the cache path.
- Modernize refuses with a clear message.
- Suggestion offered: copy the skill to `<config>/skills/` first, then re-run.
- No backup is created (no mutation attempted).

**Failure modes:**
- FAIL: Modernize proceeds and edits the cache.
- FAIL: Backup is created despite refusal.
- FAIL: User is not given a copy-first suggestion.

---

## Aggregate pass criteria

For an overall PASS:
- All RED scenarios PASS.
- GREEN scenarios may FAIL — they're advisory.
- Any RED scenario in SKIP state means overall is NOT-YET-PASS, never PASS.

For the self-audit (#11) to PASS, the rest of the suite must also conceptually pass — a skill that fails its own scenarios should not score A on its own audit.
