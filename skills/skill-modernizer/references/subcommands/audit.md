# `audit <path>` — full audit with checklist + letter grade

**Loads on entry:**
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `references/state-schema.md`
- `rules/script-hygiene.md` (only if target has `scripts/`)
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, read-only

---

## Workflow

```
LOAD → SCAN → REPORT
```

Never mutates anything. Appends one line to audit history JSONL on completion.

---

## Steps

1. **Pre-gate.**
   - Resolve `<path>` to absolute. STOP if it doesn't exist.
   - Verify a `SKILL.md` exists at the root. STOP otherwise.
   - Reject paths inside any plugins-cache directory if mutation is implied (here, audit is read-only so cache paths are allowed; emit a banner that this is a cache target and any modernize would need a copy first).

2. **Detect archetype.**
   - Inspect frontmatter for explicit `archetype:` key (preferred).
   - If absent, infer:
     - `references/subcommands/` directory present → `orchestrator-with-subcommands`.
     - SKILL.md mentions explicit gates / approvals → `single-purpose-rigid`.
     - SKILL.md is judgment-driven (no gates, no rigid steps) → `single-purpose-flexible`.
     - SKILL.md is short (< 100 lines) and contains no actionable workflow → `reference-only`.
   - When inference is ambiguous, set `archetype = "unknown"` and proceed; rubric handles `unknown` by using `single-purpose-rigid` weights as a conservative default and flags it in notes.

3. **Scan against the catalog.**
   - For each pattern in `rules/pattern-catalog.md`:
     - Apply detection rule (forgiving match — see catalog).
     - Emit `present` / `partial` / `absent` / `n/a`.
     - When `partial`, write a 1-2 sentence note explaining what's missing.
     - When `absent` and a fix is straightforward, suggest `file:line` for the fix.

4. **Run script hygiene checks.**
   - Only when target has `scripts/`. Load `rules/script-hygiene.md`.
   - Append findings to `audit.scriptHygiene`.

5. **Compute grades.**
   - Per-pattern letter from finding (per `rules/scoring-rubric.md`).
   - Weighted GPA using archetype-specific weights.
   - Overall letter from GPA threshold.

6. **Emit report.**

7. **Append history entry** to `<config>/.skill-modernizer/history.jsonl`.

---

## Report format (default, human-readable)

```
Skill: <name> (v<semver>) — archetype: <archetype>
Path:  <absolute-path>
Date:  <ISO>

Pattern checklist
─────────────────────────────────────────────────────────────
 #  Pattern                              Finding   Letter  Notes
 1  Decision graph                       ✓         A       —
 2  Red Flags                            ~         C       Only 2 items; threshold is 4
 3  Rationalization Defense              ✗         F       Section missing
 4  TodoWrite atomic checklists          ✓         A       —
 5  Announce-before-act                  ✓         A       —
 6  Rigid/Flexible labeling              ✓         A       —
 7  allowed-tools frontmatter            ✓         A       —
 8  references/ progressive disclosure   —         —       n/a (single-purpose)
 9  Self-test                            ✗         F       references/skill-self-test.md absent
10  Provides/Consumes                    ✗         C       Optional but recommended

Weighted GPA: 2.71
Overall grade: B

Suggested fixes
───────────────
- SKILL.md:120  Extend Red Flags table to ≥ 4 items (pattern #2)
- SKILL.md:end  Add Rationalization Defense section (pattern #3)
- references/skill-self-test.md  Create with at least 5 scenarios (pattern #9)
```

---

## Report format (with `--json`)

Schema in `rules/json-schema.md`. Top level looks like:

```json
{
  "version": "1.0",
  "skill": "<name>",
  "path": "<absolute-path>",
  "archetype": "<archetype>",
  "patterns": [...],
  "weighted_gpa": 2.71,
  "overall_grade": "B",
  "history_recent": [...]
}
```

`history_recent` is the last 5 entries from history JSONL for this skill, included for trend context.

---

## With `--history`

Prints the full timeline for one skill from the JSONL history. Useful for showing that a skill went C → A after modernization, or A → B after a partial regression.

---

## Common omissions to look for

- **`partial` Red Flags**: 1-3 items present (below threshold).
- **`partial` Rationalization Defense**: rows exist but missing the second column.
- **`absent` Self-test**: file exists but contains no scenarios.
- **`partial` Provides/Consumes**: only one of the two sections present.

When `partial` is borderline, prefer the more lenient finding and note the borderline state — modernize will get a chance to firm it up.

---

## What `audit` never does

- Never edits files.
- Never installs composers.
- Never creates backups.
- Never runs `pressure-test`.
- Never recommends a third-party action without an explicit `Suggest:` prefix.

It only reads, scores, and reports.
