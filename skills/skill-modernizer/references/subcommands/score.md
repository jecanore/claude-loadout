# `score <path>` — letter grade only

**Loads on entry:**
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `references/state-schema.md`
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, read-only

---

## Workflow

```
LOAD → SCAN → SCORE
```

Identical scan to `audit` but emits only the grade. Suitable for CI pre-checks or pre-commit hooks where the full report would be noise.

---

## Steps

1. **Pre-gate** — same as `audit`.
2. **Detect archetype** — same as `audit`.
3. **Scan** — same as `audit`.
4. **Compute grade** — per `rules/scoring-rubric.md`.
5. **Emit one-line grade.**
6. **Append history entry** with action `score`.

---

## Report format (default)

```
<name> (v<semver>): A   [archetype: orchestrator-with-subcommands; GPA 3.82]
```

Single line. Optionally with a one-line breakdown if the grade is below A:

```
<name> (v<semver>): C   [Red Flags ✗, Self-test ✗ — run `audit` for details]
```

The breakdown lists only `absent` patterns. If more than 3, lists the top 3 weighted and appends `+N more`.

---

## Report format (with `--json`)

```json
{
  "version": "1.0",
  "skill": "<name>",
  "overall_grade": "A",
  "weighted_gpa": 3.82,
  "archetype": "orchestrator-with-subcommands"
}
```

Minimal. No pattern array. Use `audit --json` when you need detail.

---

## Pre-commit / CI usage

```bash
grade=$(/skill-modernizer score --json "$skill_path" | jq -r '.overall_grade')
[[ "$grade" =~ ^[AB]$ ]] || exit 1
```

Exit codes:
- `0` — graded successfully.
- `1` — pre-gate failed (path missing, no SKILL.md). The grade is not emitted.
- (Grade thresholds are not encoded in exit code; that's the caller's policy.)

---

## When to use score vs audit

| Scenario | Use |
|---|---|
| Curious about overall quality | `score` |
| About to modernize | `audit` (need the checklist) |
| CI gate on every PR | `score --json` (cheaper) |
| Investigating a regression | `audit --history` |
| Reviewing a third-party skill | `audit` |

---

## What `score` never does

Same prohibitions as `audit`. Never mutates. Never installs. Never creates backups.
