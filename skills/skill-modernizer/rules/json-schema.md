# JSON output schema

**Loaded by:** any subcommand invoked with `--json`

**Version:** 1.0

**Forward-compat policy:** the `version` field at the top of every JSON payload MUST be present. Major version bumps signal breaking schema changes; minor version bumps signal additive changes. Consumers should ignore unknown keys.

---

## Top-level wrapper

Every JSON output is wrapped:

```json
{
  "version": "1.0",
  "tool": "skill-modernizer",
  "tool_version": "<semver>",
  "subcommand": "<name>",
  "ts": "<ISO-timestamp>",
  "args": { /* subcommand-specific */ },
  "result": { /* payload, see schemas below */ },
  "errors": [],
  "warnings": []
}
```

`errors` and `warnings` are always present (may be empty arrays). Each entry:

```json
{ "code": "<machine-readable>", "message": "<human-readable>", "context": { /* optional */ } }
```

---

## Per-subcommand `result` schemas

### `audit`

```json
{
  "skill": "<name>",
  "path": "<absolute-path>",
  "archetype": "orchestrator-with-subcommands | single-purpose-rigid | single-purpose-flexible | reference-only | unknown",
  "patterns": [
    {
      "id": 1,
      "name": "Decision graph",
      "finding": "present | partial | absent | n/a",
      "letter": "A | B | C | D | F | null",
      "weight": 1.5,
      "notes": "<string>",
      "fix_hint": "<file:line> | null"
    }
    /* ... */
  ],
  "weighted_gpa": 3.82,
  "overall_grade": "A | B | C | D | F",
  "script_hygiene": [
    /* ScriptHygieneFinding entries; absent or empty array if target has no scripts/ */
  ],
  "history_recent": [
    { "ts": "<ISO>", "action": "audit", "score": "B", "ver": "0.2.0" }
  ]
}
```

### `score`

```json
{
  "skill": "<name>",
  "overall_grade": "A | B | C | D | F",
  "weighted_gpa": 3.82,
  "archetype": "<archetype>",
  "weakest_patterns": [ "Red Flags", "Self-test" ]
}
```

`weakest_patterns` lists at most 3 absent patterns ordered by weight desc; absent if grade is A.

### `audit-all`

```json
{
  "scope": "<absolute-path>",
  "skills_count": 25,
  "parallelism": 10,
  "skills": [
    /* one audit-shaped entry per skill (without history_recent for compactness) */
  ],
  "cross_skill_findings": [
    { "kind": "format-variance", "subject": "Red Flag voice", "details": "<string>" }
  ],
  "unknown_batches": []
}
```

`unknown_batches` lists any agent-batch that failed; each entry: `{ "skills": ["a", "b"], "reason": "<string>" }`. Skills in `unknown_batches` also appear in `skills[]` with `"overall_grade": null` and a warning entry.

### `pressure-test`

```json
{
  "skill": "<name>",
  "scenarios": [
    {
      "name": "Frontmatter validity",
      "color": "RED | GREEN",
      "result": "PASS | FAIL | SKIP",
      "skip_reason": "<string> | null",
      "details": "<string>"
    }
  ],
  "overall": "PASS | FAIL",
  "reduced_rigor": false,
  "report_file": "<absolute-path-to-report-md>"
}
```

`overall` is `PASS` only if every RED scenario is `PASS`. SKIP on a RED scenario is treated as not-yet-PASS — it never grants overall PASS.

### `modernize`

```json
{
  "skill": "<name>",
  "pre_audit_grade": "C",
  "post_audit_grade": "A",
  "version_before": "0.1.0",
  "version_after": "0.2.0",
  "edits_applied": [
    { "file": "<rel-path>", "action": "add-section | replace-section | extract-to-reference", "rationale": "<pattern-name>" }
  ],
  "backup_path": "<absolute-path>",
  "approved": true
}
```

If `approved: false`, no edits were applied; `edits_applied` is empty and the skill state is unchanged.

### `migrate`

```json
{
  "skill": "<name>",
  "version_before": "0.1.0",
  "version_after": "1.0.0",
  "extracted_files": [
    { "to": "<rel-path>", "lines_extracted": 142, "from_section": "<heading>" }
  ],
  "skill_md_lines_before": 612,
  "skill_md_lines_after": 408,
  "lines_lost": 0,
  "backup_path": "<absolute-path>",
  "approved": true
}
```

`lines_lost` MUST be `0`. If the migration would lose lines, the gate must surface this and the user must explicitly approve. `approved: false` means no changes applied.

### `create`

```json
{
  "skill": "<name>",
  "archetype": "<archetype>",
  "scaffold_files": [
    { "path": "<rel-path>", "lines": 142 }
  ],
  "auto_pressure_test": {
    "overall": "PASS | FAIL",
    "scenarios_run": 7,
    "scenarios_passed": 7
  }
}
```

### `refresh`

```json
{
  "tool_version_before": "1.2.0",
  "tool_version_after": "1.3.0",
  "sources_queried": [
    { "name": "<source-name>", "url": "<url>", "ok": true, "fetched_at": "<ISO>" }
  ],
  "findings": [
    { "kind": "new-pattern | updated-detection | deprecated-pattern | rubric-shift",
      "pattern_id": 11, "description": "<string>", "evidence_urls": [] }
  ],
  "conflicts": [],
  "approved": true,
  "self_audit_grade_after": "A"
}
```

### `prune-backups`

```json
{
  "scanned": 47,
  "deleted": 12,
  "retained": 35,
  "retention_policy": { "max_per_skill": 3, "ttl_days": 30, "unverified_extra_days": 7 },
  "deleted_paths": [ "<absolute-path>" ]
}
```

---

## Stability guarantees

- Field names within a `result` block are stable across patch and minor releases.
- Adding a new field is a minor version bump.
- Removing or renaming a field is a major version bump.
- Enum values within a field (`finding`, `letter`, `result`, etc.) may be extended in minor releases; consumers should treat unknown enum values as a category they don't understand and degrade gracefully (typically: treat unknown grade as `unknown`, unknown finding as `partial`).

---

## CI exit codes

When any subcommand is invoked with `--json`:
- Exit `0` when the command completed successfully (regardless of grade).
- Exit `1` when pre-gate failed (path missing, etc.).
- Exit `2` when an internal error occurred (the JSON payload still emits with `errors` populated).

CI gates that want to fail on grade thresholds should parse `result.overall_grade` and decide.
