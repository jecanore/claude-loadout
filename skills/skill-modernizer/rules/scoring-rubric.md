# Scoring Rubric — Letter grades for skill quality

**Purpose:** Compute a per-pattern letter grade and an overall letter grade for a skill. Archetype-aware: a `reference-only` skill is not penalized for missing a decision graph.

**Loaded by:** `audit`, `score`, `modernize` (post-apply re-scoring)

**Version:** 1.0

---

## Per-pattern grade

For each of the 10 patterns in `pattern-catalog.md`, the auditor produces one of:

| Finding | Per-pattern letter |
|---|---|
| `present` (✓)  | A |
| `partial` (~)  | C |
| `absent` (✗) and required by archetype | F |
| `absent` (✗) and recommended by archetype | C |
| `absent` (✗) and optional by archetype | B |
| `n/a` (—) by archetype | excluded from average |

`partial` is reserved for cases where the pattern is structurally present but materially incomplete (e.g., Red Flags section exists with only 1 item; threshold is 4).

---

## Archetype weight table

Weights apply when computing the overall grade. A pattern weighted `0` is excluded from the grade for that archetype.

| # | Pattern | orchestrator | rigid | flexible | reference-only |
|---|---|---|---|---|---|
| 1  | Decision graph             | 1.5 | 1.5 | 1.0 | 0   |
| 2  | Red Flags                  | 1.5 | 1.5 | 1.5 | 1.0 |
| 3  | Rationalization Defense    | 1.5 | 1.5 | 1.0 | 0.5 |
| 4  | TodoWrite-atomic checklist | 1.0 | 1.0 | 0.5 | 0   |
| 5  | Announce-before-act        | 1.0 | 1.0 | 0.5 | 0.5 |
| 6  | Rigid/Flexible labeling    | 1.0 | 1.0 | 1.0 | 0   |
| 7  | `allowed-tools` frontmatter| 1.0 | 1.0 | 1.0 | 0   |
| 8  | `references/` disclosure   | 1.0 | 0.5 | 0.5 | 0   |
| 9  | Self-test                  | 1.5 | 1.5 | 0.5 | 0   |
| 10 | Provides/Consumes          | 0.5 | 0.5 | 0.5 | 0.5 |

Patterns with weight `0` for an archetype are reported as `n/a` in the audit output.

---

## Letter grade thresholds

Per-pattern letter → numeric:

| Letter | Numeric |
|---|---|
| A | 4.0 |
| B | 3.0 |
| C | 2.0 |
| D | 1.0 |
| F | 0.0 |

**Weighted GPA** = Σ(letter_numeric × weight) / Σ(weights), excluding `n/a`.

**Overall letter:**

| Weighted GPA | Overall grade |
|---|---|
| ≥ 3.7 | A |
| ≥ 3.0 | B |
| ≥ 2.0 | C |
| ≥ 1.0 | D |
| < 1.0 | F |

---

## Special cases

- **No patterns applicable** (e.g., empty file): grade is `F` with note "skill has no detectable structure".
- **All patterns `present`**: grade is `A` with note "10/10 ✓".
- **One required pattern `absent` and rest `present`**: typically lands a `B` due to weight; rubric does not artificially clamp.

---

## Output schema for grade computation

When emitting JSON, the grade block looks like:

```json
{
  "archetype": "orchestrator-with-subcommands",
  "patterns": [
    {"id": 1, "name": "Decision graph", "finding": "present", "letter": "A", "weight": 1.5, "notes": "..."},
    ...
  ],
  "weighted_gpa": 3.82,
  "overall_grade": "A"
}
```

---

## When the rubric should evolve

Mutations to this file are governed by `refresh`. Manual edits are allowed; follow with a self-audit pass. If weights shift, document the rationale in the JSONL audit history.

Rationale for current weights:
- **Red Flags + Rationalization** carry the highest aggregate weight because they are the patterns most likely to be omitted by reflex. They're the discipline-enforcing core.
- **Decision graph + Self-test** are weighted high because they're the most expensive to retrofit. Building them in early is much cheaper than later.
- **Provides/Consumes** is weighted low because composability matters most for ecosystem skills, less for standalone ones.
