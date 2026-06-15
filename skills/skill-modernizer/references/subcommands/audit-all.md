# `audit-all [scope]` — bulk audit across a skills directory

**Loads on entry:**
- `rules/parallel-dispatch.md`
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `references/state-schema.md`
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, read-only

---

## Workflow

```
DISPATCH → AGGREGATE → REPORT
```

Never mutates anything. Each dispatched agent is itself read-only. The main thread appends one summary line to audit history JSONL on completion (per skill audited, action `audit`).

---

## Steps

1. **Pre-gate.**
   - Resolve `[scope]` to absolute. Default scope: the user's skills directory (`$CLAUDE_HOME/skills/`). STOP if it doesn't exist.
   - Verify the scope is a directory. STOP if it's a single skill (the user wants `audit`, not `audit-all`).
   - Cache directories (`*/plugins/cache/*`) inside the scope are **included** by default — bulk audit is read-only, so cache targets are safe to score. Emit a banner per cache target noting that any modernize would require copy-out first.

2. **Enumerate skills in scope.**
   - A skill = directory containing a `SKILL.md` at its root.
   - Walk one level deep by default (configurable with `--recursive`). The default user skills layout is flat.
   - Skip directories that match `.backups/`, `node_modules/`, `dist/`, or any path component starting with `.` (except the scope itself).
   - Sort discovered skills by name for deterministic batch assignment.

3. **Plan parallelism.**
   - Load `rules/parallel-dispatch.md`.
   - Compute `batch_size` (default `5`, override `--batch-size N`).
   - Compute `parallelism` (default `10`, override `--parallelism N`).
   - Number of batches = `ceil(skills_count / batch_size)`.
   - Emit a one-line announce: "Auditing N skills across B batches with P concurrent agents."

4. **Dispatch one Explore subagent per batch.**
   - Each agent receives:
     - The list of absolute skill paths in its batch.
     - The catalog and rubric content (or pointers to load them).
     - The expected JSON output shape from `rules/json-schema.md` (`audit-all.skills[]` entries match the `audit` `result` shape minus `history_recent`).
     - Strict instructions: do NOT write files; do NOT spawn further agents; return structured JSON only.
   - Use the prompt template in `rules/parallel-dispatch.md` § 4.
   - Concurrency cap honored by the parallel-dispatch primitive: never exceed `parallelism`.

5. **Aggregate.**
   - Wait for all agents to complete (or time out).
   - Collect each agent's structured output.
   - Merge per-skill findings into `result.skills[]`.
   - Compute cross-skill consistency findings (see § Cross-skill consistency findings).
   - Build `result.unknown_batches[]` from any agent that failed or timed out.
   - For each skill in a failed batch, emit a stub entry in `result.skills[]` with `overall_grade: null`, `weighted_gpa: null`, and `patterns: []`. **Never drop a skill from the report.**

6. **Emit report.**

7. **Append history entries.** One per successfully-audited skill. Skills in failed batches do not get a history entry (since they have no grade).

---

## Parallelism flags

| Flag | Default | Effect |
|---|---|---|
| `--batch-size N` | 5 | Skills per agent. Larger N reduces agent count but increases per-agent context. |
| `--parallelism N` | 10 | Maximum concurrent agents. Lower on resource-constrained machines. |
| `--recursive` | off | Walk nested directories instead of one level. |
| `--timeout-per-agent S` | 300 | Per-agent timeout in seconds. On timeout, agent is treated as failed. |
| `--json` | off | Emit machine-readable output per `rules/json-schema.md`. |
| `--include-cache` | on | Set `--no-include-cache` to skip plugin cache targets. |

---

## Aggregation rules

- **Per-skill ordering** in `result.skills[]` follows the same sort order used for batch assignment (alphabetical by skill name). Stable across runs on the same scope.
- **Failed batches**: every skill in a failed batch appears in `result.skills[]` with:
  ```json
  {
    "skill": "<name>",
    "path": "<abs>",
    "archetype": "unknown",
    "patterns": [],
    "weighted_gpa": null,
    "overall_grade": null
  }
  ```
  The batch is also listed in `result.unknown_batches[]` with the failure reason.
- **Per-agent JSON parse failure** is treated as a batch failure for the entire batch (don't try to salvage partial output).
- **Warnings** are accumulated into the top-level `warnings[]` array (one entry per failed batch, plus any cross-skill anomalies that aren't blocking).
- **Errors** are populated only if the run cannot proceed (scope missing, every batch failed). A run with at least one successful batch is `errors: []` even if other batches failed.

---

## Cross-skill consistency findings

These surface patterns across the **whole audit set**, not within a single skill. They appear in `result.cross_skill_findings[]`. Examples (non-exhaustive — see `rules/parallel-dispatch.md` § 7 for the full menu):

- **Announce-format inconsistency.** Some skills say `Announce: <one line>`, others `State in one sentence: ...`, others embed the announce inside a Workflow heading. Suggest normalizing to one phrasing.
- **Red Flag voice variance.** Some skills use second-person ("You should..."), others third-person ("The skill should..."). Suggest a convention (typically second-person).
- **Archetype concentration.** If 80%+ of skills share one archetype and the user expected diversity, flag explicitly.
- **Pattern-coverage gaps.** A pattern absent in 70%+ of audited skills suggests either a fleet-wide gap or a catalog mismatch — surface it so the user can decide.
- **Versioning drift.** Skills with `version: 0.0.0` or no version frontmatter at all — count and list.

Each finding is non-blocking; it informs a follow-up `modernize` or a fleet-wide convention decision.

Cross-skill findings are computed only over **successfully-audited** skills. Unknown-batch skills are excluded from the denominator.

---

## Report format (default, human-readable)

```
Bulk audit
──────────
Scope:       <absolute-path>
Skills:      25 found, 23 audited, 2 unknown
Parallelism: 10 agents × 5-skill batches = 5 batches
Date:        <ISO-timestamp>

Per-skill grades
─────────────────────────────────────────────────────────────
  Skill                              Archetype                   Grade  GPA
  abc-tool                           single-purpose-rigid        A      3.81
  bulk-importer                      orchestrator-with-subcmds   B      3.12
  caching-helper                     single-purpose-flexible     C      2.40
  ...
  unknown-batch-skill-1              —                           —      —
  unknown-batch-skill-2              —                           —      —

Cross-skill findings
─────────────────────────────────────────────────────────────
- Announce format variance: 12 skills use "Announce:", 8 use "State in one sentence:", 3 omit. Suggest normalization.
- Red Flag voice variance: 14 second-person, 9 third-person.
- Archetype concentration: 18/23 are `single-purpose-rigid`.
- Versioning drift: 4 skills have no `version:` field.

Unknown batches
─────────────────────────────────────────────────────────────
- batch 4 (skills: unknown-batch-skill-1, unknown-batch-skill-2): agent timeout after 300s.

Suggested next steps
─────────────────────────────────────────────────────────────
- Re-run failed batches with `--batch-size 2 --timeout-per-agent 600`.
- For the lowest-grade skills, run `audit <path>` to see per-pattern detail.
- For announce-format variance, decide on a convention and `modernize` outliers.
```

---

## Report format (with `--json`)

Schema in `rules/json-schema.md` under the `audit-all` section. Top level:

```json
{
  "version": "1.0",
  "tool": "skill-modernizer",
  "subcommand": "audit-all",
  "ts": "<ISO-timestamp>",
  "args": { "scope": "<abs>", "batch_size": 5, "parallelism": 10 },
  "result": {
    "scope": "<absolute-path>",
    "skills_count": 25,
    "parallelism": 10,
    "skills": [ /* per-skill audit-shaped entries */ ],
    "cross_skill_findings": [
      { "kind": "format-variance", "subject": "Announce phrasing", "details": "12/23 use 'Announce:', 8 use 'State in one sentence:'" }
    ],
    "unknown_batches": [
      { "skills": ["unknown-batch-skill-1", "unknown-batch-skill-2"], "reason": "agent timeout after 300s" }
    ]
  },
  "errors": [],
  "warnings": [
    { "code": "batch-failure", "message": "1 batch failed (2 skills affected)", "context": { "batch_index": 4 } }
  ]
}
```

Each `result.skills[i]` matches the `audit` `result` shape (see `rules/json-schema.md` § `audit`) minus `history_recent` (omitted for compactness in bulk output). Failed-batch skills appear with `"overall_grade": null` and `"weighted_gpa": null`.

---

## Failure handling

| Failure | Behavior |
|---|---|
| Scope path missing | STOP with pre-gate error. Exit code 1. No JSON `result` block. |
| Scope path is a single skill (has SKILL.md at root) | STOP. Suggest `audit <path>`. |
| One agent crashes | Mark batch as failed; aggregate as `unknown` for its skills; continue. |
| One agent times out | Same as crash. Configurable timeout. |
| One agent returns malformed JSON | Same as crash; record `reason: "malformed agent output"`. |
| All agents fail | Surface as overall failure: populate top-level `errors[]`; `result.skills[]` still lists every targeted skill with `overall_grade: null`. Exit code 2 with `--json`; non-zero in default mode. |
| Mid-run interrupt (SIGINT) | Cancel pending agents; emit partial report covering completed batches; mark remaining as unknown with reason `interrupted`. |

A single agent failure NEVER fails the overall run.

---

## What `audit-all` never does

- Never edits files in any skill it audits.
- Never installs composer skills.
- Never creates backups (no mutation).
- Never spawns further nested agents from inside a dispatched agent (the dispatched agents are leaves).
- Never silently drops a skill from the report — failed batches always appear with `overall_grade: null`.
- Never collapses cross-skill findings into per-skill notes — cross-skill findings are a separate output channel.
- Never overrides per-agent timeout silently — if you set `--timeout-per-agent`, the value is honored exactly.
- Never recommends a third-party action without an explicit `Suggest:` prefix.

It only reads, scores in parallel, aggregates, and reports.
