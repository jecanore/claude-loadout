# `create <name>` — archetype-aware scaffold for a new skill

**Loads on entry:**
- `rules/archetypes.md`
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `references/state-schema.md`
- `references/scenario-catalog.md` (for the auto pressure-test step)
- `references/skill-self-test.md` (template stub source for archetypes that need self-tests)
- `rules/json-schema.md` (only with `--json`)

**Type:** flexible, mutating

---

## Workflow

```
ARCHETYPE → WIZARD → SCAFFOLD → PRESSURE-TEST → REVIEW
```

Mutating: writes a new skill directory under `$CLAUDE_HOME/skills/<name>/`. Always creates a backup index entry; only creates a snapshot backup when `--overwrite` is used against an existing directory.

---

## Steps

1. **Pre-gate.**
   - Resolve `<name>` to a kebab-case identifier. STOP if `<name>` is missing, contains spaces, or contains uppercase characters; suggest a normalized form.
   - Compute the target directory: `$CLAUDE_HOME/skills/<name>/`.
   - **Collision check.** If the target directory already exists:
     - Without `--overwrite`: STOP. Emit the existing skill's grade (one-line `score`-style summary) and propose 3 alternative names: `<name>-v2`, `<name>-next`, `<name>-2`. Do not write anything.
     - With `--overwrite`: snapshot the existing directory to the backup namespace per the Backup module in `SKILL.md`, write an `unverified` index entry, and proceed.
   - Reject paths inside any plugins-cache directory; suggest a personal skills directory instead.

2. **Archetype selection** (`AskUserQuestion`).
   - Present the 4 archetypes from `rules/archetypes.md`. The selection determines the scaffold layout, the rubric weight column, and which patterns the wizard prompts will gather.

3. **Wizard prompts** (6-8 `AskUserQuestion` calls; see "Wizard prompts" below).
   - Each prompt is one `AskUserQuestion` call. Never batch unrelated questions.
   - The orchestrator-only `subcommand list` prompt is skipped for non-orchestrator archetypes.

4. **Scaffold the file tree** per `rules/archetypes.md`.
   - Write every file in the archetype's tree using the Write tool, one file per call.
   - All Red Flags / Rationalization / decision-graph / self-test sections are emitted as **stubs** with explicit `[scaffold placeholder — replace before shipping]` markers so users know what to customize.
   - Frontmatter `version:` defaults to `0.1.0`.
   - Frontmatter `name:` is the kebab-case identifier from the wizard.
   - Frontmatter `description:` is the wizard's "Use when..." string, verbatim.
   - Frontmatter `allowed-tools:` is the multi-select result.

5. **Auto pressure-test.**
   - Invoke `pressure-test <new-skill-path>` against the scaffold immediately after writing.
   - Use a reduced scenario set focused on stub completeness (see "Auto pressure-test" below).
   - Report the pressure-test result alongside the scaffold report.

6. **Re-audit.**
   - Run `audit <new-skill-path>` against the freshly written scaffold to surface a baseline grade. Expect a `B` or `C` for stubs (placeholders register as `partial`); the wizard's job is to plant patterns, not fill them.

7. **Emit report.** See "Report format" below.

8. **Append history entry** with action `create` to `$CLAUDE_HOME/.skill-modernizer/history.jsonl`.

9. **Mark backup as `verified`** (only when `--overwrite` was used and the auto pressure-test passed without RED scenarios).

---

## Wizard prompts

Each prompt is a single `AskUserQuestion` call. Order matters — later prompts reference earlier answers (e.g., subcommand list seeds rigid/flexible labeling).

1. **`name`** — confirm the kebab-case identifier.
   - Default: the `<name>` argument.
   - Validation: matches `^[a-z][a-z0-9-]*$`.

2. **`description`** — must follow the "Use when..." formula.
   - Prompt copy: "One-sentence description starting with 'Use when'. Include 3-5 trigger phrases the harness should match."
   - The wizard rejects descriptions that don't begin with `Use when`; offer to prepend it.

3. **Trigger phrases** — 3-5 typical user prompts that should activate this skill.
   - Free-text list. The wizard concatenates these into the description.

4. **`allowed-tools`** — multi-select.
   - Options: `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `AskUserQuestion`, `Task`, `WebFetch`, `WebSearch`, `TodoWrite`, plus a free-text "Other" entry.
   - Validation: at least one tool selected unless archetype is `reference-only`.

5. **Rigid vs flexible labeling.**
   - For `single-purpose-rigid` / `single-purpose-flexible` / `reference-only`: one selection covers the whole skill.
   - For `orchestrator-with-subcommands`: the wizard asks per subcommand (after prompt 6).

6. **Subcommand list** — only for `orchestrator-with-subcommands`.
   - Prompt copy: "List the subcommand verbs (e.g., `audit`, `modernize`). Each becomes a `references/subcommands/<verb>.md` stub."
   - The wizard then asks rigid/flexible per subcommand in a follow-up `AskUserQuestion`.

7. **Composition with other skills.**
   - Multi-select: `superpowers:writing-skills`, `Remote_Skill_Security_Check`, `find-skills`, plus free-text.
   - Each selection becomes a row in the scaffold's `## Consumes` section with a detect-and-offer-install stub.

8. **Final confirmation.**
   - Single-select: `[c]reate now` / `[r]eview answers` / `[a]bort`.
   - On `r`, the wizard re-emits answers and re-asks any flagged for change.
   - On `a`, no files are written; nothing is logged.

---

## Scaffold layout

The exact tree per archetype lives in `rules/archetypes.md`. This subcommand never inlines templates — it always reads the archetype's section and writes from there. Any archetype-specific deviation (extra sample files, alternate frontmatter keys) is governed by `rules/archetypes.md`, not by this reference.

When writing files:
- Use `Write` (not `Edit`) for every scaffold file. The target directory is new (or freshly cleared post-overwrite), so there is nothing to merge.
- Write one file per call. Do not batch.
- After every file write, advance the matching TodoWrite item to `completed`.

---

## Auto pressure-test

After scaffold, invoke `pressure-test` with the `--scaffold` flag. This runs a reduced scenario set focused on the patterns the wizard claims to have planted:

- Each Red Flags table has > 0 rows that are not `[scaffold placeholder — replace before shipping]`.
- Each Rationalization Defense table has > 0 rows.
- Decision-graph fenced block parses (when archetype requires one).
- Self-test file exists with > 0 scenarios (when archetype requires one).
- `allowed-tools` frontmatter is non-empty (unless `reference-only`).
- `version: 0.1.0` is present.

Failing scenarios are surfaced as `STUB` findings, not `FAIL`. The user expects stubs after a fresh scaffold; pressure-test's job is to confirm the stub *structure* exists, not that the user has filled them in. A truly empty section (heading missing entirely) is a `FAIL`.

If any `FAIL` surfaces, the create report includes a remediation block pointing at the offending file:line.

---

## Report format (default, human-readable)

```
Created skill: <name> (v0.1.0)
Archetype:     <archetype>
Path:          $CLAUDE_HOME/skills/<name>/

Scaffold files written
──────────────────────────────────────────────────────────
  SKILL.md
  references/<...>.md
  rules/<...>.md (orchestrator only)
  ... (full tree per archetype)

Auto pressure-test
──────────────────────────────────────────────────────────
  Stubs structurally present:    8/8
  STUB findings (expected):      6
  FAIL findings (must fix):      0

Baseline audit
──────────────────────────────────────────────────────────
  Weighted GPA: 2.40
  Overall grade: C  (stubs in place; fill before shipping)

Next steps
──────────────────────────────────────────────────────────
  1. Replace [scaffold placeholder] markers in SKILL.md.
  2. Fill self-test scenarios (when applicable).
  3. Run `/skill-modernizer audit $CLAUDE_HOME/skills/<name>/` after edits.
  4. When grade ≥ B, run pressure-test without `--scaffold` for full rigor.
```

---

## Report format (with `--json`)

Schema in `rules/json-schema.md`. Top level:

```json
{
  "version": "1.0",
  "skill": "<name>",
  "path": "<absolute-path>",
  "archetype": "<archetype>",
  "filesWritten": ["<relative-path>", "..."],
  "pressureTest": {
    "stubsPresent": 8,
    "stubFindings": 6,
    "failFindings": 0,
    "scenarios": [...]
  },
  "baselineAudit": {
    "weighted_gpa": 2.40,
    "overall_grade": "C"
  },
  "overwroteExisting": false,
  "backupPath": null
}
```

`overwroteExisting` and `backupPath` are populated when `--overwrite` was used.

---

## Provides

- A new skill directory at `$CLAUDE_HOME/skills/<name>/` with all 10 patterns structurally planted.
- A baseline audit grade for the freshly scaffolded skill.
- A backup snapshot (only when `--overwrite` was used).

## Consumes

- `rules/archetypes.md` for tree layouts and per-archetype templates.
- `rules/pattern-catalog.md` for pattern detection and stub structure.
- `rules/scoring-rubric.md` for the baseline audit's archetype weighting.
- `references/scenario-catalog.md` for the reduced auto pressure-test scenario set.
- `superpowers:writing-skills` (optional) — when present, citations to its Common Rationalizations table are wired into the scaffold's Rationalization Defense section as a starter row.
- `Remote_Skill_Security_Check` (optional) — when present, the scaffold's `## Consumes` section includes a stub for security-checking remote skills before composition.

---

## Red Flags

These thoughts mean STOP. You are rationalizing.

- Running `create` and overwriting an existing skill directory without explicit user approval. `--overwrite` requires explicit user intent; it is never inferred.
- Skipping the auto pressure-test after scaffold ("the scaffold is correct by construction"). Wizard fills templates; templates can have empty stubs. Always pressure-test post-scaffold.
- Writing the scaffold tree before the wizard's final confirmation. The user can abort up to that point with zero side effects.
- Inferring `archetype` from the user's name argument or trigger phrases. The archetype prompt is mandatory; never guess.
- Filling Red Flags / Rationalization rows with generic content (e.g., "don't skip steps"). The scaffold uses explicit `[scaffold placeholder — replace before shipping]` markers; generic filler is worse than honest placeholders because it hides the gap.
- Auto-installing a composer skill (e.g., `superpowers:writing-skills`) because the wizard selected it for composition. Composition is declared in frontmatter and `## Consumes`; installation is a separate gate handled by SKILL.md's composition flow.

---

## Rationalization Defense

| Excuse | Reality |
|---|---|
| "The user clearly wants an orchestrator; I can skip the archetype prompt" | The user's mental model and the rubric's archetype taxonomy are different vocabularies. Always prompt; the prompt is fast and unambiguous. |
| "Scaffold is correct by construction; pressure-test is redundant" | Templates regress when the catalog evolves. Auto pressure-test is the canary that catches catalog drift before the user ships. |
| "The user typed `create my-skill` and `my-skill/` already exists; they obviously want to overwrite" | Existing skills carry hours of work. Always STOP on collision; offer alternatives; only overwrite with the explicit `--overwrite` flag. |
| "I'll fill the Red Flags rows with reasonable content so the audit grade looks better" | A B grade with placeholder markers is more honest (and more useful) than an A grade with generic filler. The marker is a signal to the user; the filler hides the gap. |
| "The wizard answers look good; I can write files in parallel for speed" | Atomic writes per file let the user abort cleanly mid-scaffold. Parallel writes leak partial state on failure. Write serially; advance TodoWrite per file. |
| "Composer skills the user selected should auto-install" | User consent is per-action. Wizard selection records intent; install is a separate gate per the SKILL.md composition flow. |

---

## TodoWrite checklist

1. Pre-gate (path normalize, collision check, cache-path rejection).
2. Archetype selection.
3. Wizard prompt: `name`.
4. Wizard prompt: `description`.
5. Wizard prompt: trigger phrases.
6. Wizard prompt: `allowed-tools`.
7. Wizard prompt: rigid/flexible (per subcommand if orchestrator).
8. Wizard prompt: subcommand list (orchestrator only; otherwise skip).
9. Wizard prompt: composition.
10. Wizard prompt: final confirmation.
11. Snapshot existing directory to backup (only when `--overwrite`).
12. Scaffold file tree (one TodoWrite item per file written).
13. Auto pressure-test.
14. Baseline re-audit.
15. Emit report.
16. Append history entry.
17. Mark backup as `verified` (only when `--overwrite` and pressure-test passed).

---

## What `create` never does

- Never writes files before the wizard's final confirmation.
- Never overwrites an existing skill directory without an explicit `--overwrite` flag.
- Never auto-installs composer skills selected during the wizard.
- Never marks a `--overwrite` backup as `verified` until the auto pressure-test passes.
- Never infers the archetype from the skill name or trigger phrases.
- Never fills Red Flags / Rationalization rows with generic content; placeholders are explicit.
- Never writes outside `$CLAUDE_HOME/skills/<name>/` (no sibling files, no parent-dir mutations).
