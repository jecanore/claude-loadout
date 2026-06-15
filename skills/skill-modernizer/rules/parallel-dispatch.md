# Parallel dispatch — fan-out patterns

**Loaded by:** `audit-all`, `refresh` (research), `pressure-test` (when scenarios independent)

**Version:** 1.0

**Purpose:** Document the fan-out primitive used by three subcommands. The patterns are parameterizable so each caller can adapt batching, prompt content, and aggregation logic without re-implementing dispatch.

---

## 1. When to fan out

Fan out only when all of the following hold:

- **Independent units of work.** Each unit can be evaluated without state shared with another unit. No unit's output influences another unit's input within the same dispatch round.
- **Each unit fits in one agent's context.** Rule of thumb: under ~5,000 tokens of input per unit (skill files, source pages, scenario setup). Larger units should be batched smaller, not packed denser.
- **Total work benefits from parallelism.** Rule of thumb: more than 4 units. Below that, the dispatch overhead is comparable to serial execution.

If any condition fails, run serially. Serial is correct when there are 1-3 skills, 1-2 research sources, or scenarios with shared setup.

A common anti-pattern: forcing parallelism on dependent work and discovering shared-state bugs at aggregation time. Independence is a hard precondition, not a preference.

---

## 2. Batching strategy

Batching maps N units onto M agents. M = ceil(N / batch_size). The right `batch_size` depends on per-unit token cost.

### `audit-all`

- Group N skills per batch. Default `N = 5`. Configurable via `--batch-size`.
- Reasoning: an average skill (SKILL.md + 1-3 references) consumes ~3,000-5,000 tokens. Five skills fits one agent's working window with headroom for the catalog and rubric.
- Larger skills (orchestrator archetype with 10+ references) may justify `--batch-size 2` or `3`.
- Smaller skills (reference-only, < 500 lines total) tolerate `--batch-size 8` or higher.

### `refresh` research

- One source per agent. Typical refresh queries 4-8 canonical sources.
- No batching needed — sources are heterogeneous and their fetch costs vary widely.
- Equivalent to `--batch-size 1`.

### `pressure-test`

- One scenario per agent **only when scenarios are independent.**
- Some scenarios depend on prior scenarios' setup (e.g., a "post-modernize state" scenario only makes sense after the "modernize completes" scenario). Run those serially.
- The scenario catalog (`rules/scenario-catalog.md`) marks each scenario as `independent` or `setup-dependent`. Only `independent` scenarios participate in fan-out.

---

## 3. Concurrency cap

- **Default:** 10 concurrent agents.
- **Configurable:** `--parallelism N` flag at the calling subcommand level.
- **Rationale for 10:** balances throughput against harness limits. Higher caps can saturate context-window budgets across the parent + children; lower caps leave throughput on the table.
- **Smaller machines** (limited memory, slower disk, constrained API rate-limits) should lower the cap. `--parallelism 4` is reasonable when running on a laptop with concurrent IDE work.
- The cap applies to **simultaneously running** agents; the total agent count is unbounded (queued).

### Sizing guidance

| Machine / context | Suggested `--parallelism` |
|---|---|
| Workstation, dedicated session | 10 (default) |
| Laptop with concurrent IDE / browser work | 4-6 |
| Constrained API rate-limit environment | 2-4 |
| CI runner with fast network | 8-12 |

Going above 16 rarely helps and often hurts: each child agent draws context budget from the parent's pool. If aggregate throughput plateaus or regresses with higher caps, lower the cap.

---

## 4. Agent prompt template

The template below is what `audit-all` uses to dispatch each batch agent. `refresh` and `pressure-test` adapt the same skeleton — the differences are the task description and the JSON output shape.

```
You are an Explore subagent dispatched by skill-modernizer's `audit-all` subcommand.

TASK: Audit each skill in your assigned batch against the pattern catalog and return
structured JSON. You are read-only. You will not write files. You will not spawn
further agents.

ASSIGNED BATCH ({batch_count} skills):
{for each skill in batch:}
  - {absolute_path_to_skill_directory}

INSTRUCTIONS:
1. For each skill in your batch:
   a. Read its SKILL.md.
   b. Read any references/ and rules/ files relevant to the pattern catalog.
   c. Detect archetype (use frontmatter `archetype:` if present; otherwise infer
      via the rules in references/subcommands/audit.md § Detect archetype).
   d. Apply each of the 10 patterns in {pattern_catalog} using the forgiving-match
      approach described there.
   e. Compute per-pattern findings: present | partial | absent | n/a.
   f. Compute weighted GPA and overall grade per {scoring_rubric}.

2. Emit ONE JSON object covering the entire batch:

   {
     "batch_skills": [
       {
         "skill": "<name>",
         "path": "<absolute-path>",
         "archetype": "<archetype>",
         "patterns": [ /* per audit.result.patterns shape */ ],
         "weighted_gpa": <number>,
         "overall_grade": "A | B | C | D | F"
       }
       /* ... one per skill in your batch ... */
     ]
   }

3. The JSON shape MUST match the `audit` result shape in rules/json-schema.md
   (omit `history_recent` — the parent will add that).

CONSTRAINTS:
- Do NOT write any files.
- Do NOT spawn further agents (no nested Task / Explore calls).
- Do NOT include narration outside the JSON. Your final output is the JSON object only.
- If a skill in your batch is unreadable (path missing, malformed frontmatter),
  emit it with `"overall_grade": "F"` and a note in `notes`. Do NOT omit it.
- If the entire batch fails before emitting JSON (you crash or exceed your budget),
  the parent will treat it as a batch failure.

OUTPUT: a single JSON object. Nothing else.
```

For `refresh` research agents, the analogous template instructs each agent to fetch one source via `WebFetch` (or `WebSearch` when the source is a query rather than a URL), extract structured findings (new patterns, updated detections, deprecations, evidence URLs), and return a `ResearchFinding[]`.

For `pressure-test` scenario agents, the template instructs each agent to set up the scenario, invoke the target skill, observe behavior, and return `{ name, color, result, details }` per the `pressure-test` schema.

All three templates share the same constraints: read-only, no nested agents, JSON-only output.

---

### Adapting the template

When `refresh` and `pressure-test` use this template, three slots change:

1. **TASK paragraph** — describe what the agent computes (audit findings, research findings, scenario outcome).
2. **INSTRUCTIONS** — list the steps specific to the task (read SKILL.md vs fetch URL vs execute scenario).
3. **OUTPUT JSON shape** — match the corresponding entry shape in `rules/json-schema.md`.

The CONSTRAINTS block is identical across all three callers and must not be relaxed. In particular: read-only, no nested agents, JSON-only output. These are non-negotiable for safe fan-out.

---

## 5. Aggregation logic

After dispatch, the main thread:

1. **Waits** for every dispatched agent to complete or time out.
2. **Collects** each agent's structured output. Parse each as JSON.
3. **Merges** into the top-level result:
   - For `audit-all`: append each batch's `batch_skills[]` entries into `result.skills[]`. Preserve the batch-assignment ordering.
   - For `refresh`: deduplicate findings (multiple sources may surface the same pattern); flag conflicts where two sources disagree.
   - For `pressure-test`: append each scenario result into `result.scenarios[]`. Compute `overall: PASS | FAIL` from RED-scenario results.
4. **Computes cross-cutting findings** that require the full set:
   - For `audit-all`: announce-format variance, Red Flag voice variance, archetype concentration. See § 7.
   - For `refresh`: which findings are corroborated by multiple sources vs. only one (corroborated findings get higher confidence in the diff preview).
   - For `pressure-test`: usually none — each scenario is self-contained.
5. **Records failures.** Any agent that crashed, timed out, or returned malformed JSON contributes to `result.unknown_batches[]` (or the equivalent failure list). Skills/sources/scenarios in failed batches still appear in the relevant output array with null grades / null findings.

---

## 6. Failure handling

| Failure mode | Aggregation behavior | Overall run status |
|---|---|---|
| Single agent crash | Batch marked failed; units in batch appear as unknown. | Run continues; `errors[]` empty, `warnings[]` populated. |
| Single agent timeout | Same as crash. | Run continues. |
| Single agent malformed JSON | Same as crash; reason `"malformed agent output"`. | Run continues. |
| All agents fail | Every unit appears unknown; top-level `errors[]` populated. | Run reports overall failure. |
| Parent interrupted (SIGINT) | Cancel pending agents; emit partial report. | Run reports interrupted; remaining units marked unknown with reason `interrupted`. |

**Default per-agent timeout:** 300 seconds (5 minutes). Configurable via `--timeout-per-agent S` at the calling subcommand.

A single agent failure NEVER fails the overall run. This is a hard rule — silently dropping a unit because its batch crashed is a Red Flag (see SKILL.md). Always surface failed batches in the report.

Recovery suggestion in the report: "Re-run failed batches with smaller `--batch-size` and longer `--timeout-per-agent`."

---

## 7. Cross-skill consistency findings (for `audit-all`)

These findings emerge only from comparing skills against each other. The dispatched agents cannot compute them — they only see their own batch. The main thread computes them after aggregation, over **successfully-audited** skills only (unknown-batch skills are excluded from the denominator).

Standard findings to compute:

- **Announce-format variance.** Bucket skills by the phrasing they use for the announce-before-act pattern (`Announce:`, `State in one sentence:`, `Before any tool call, write...`, `<other>`, `<absent>`). Report buckets and counts. If more than one bucket has > 20% share, flag as variance and suggest normalization.

- **Red Flag voice variance.** Detect grammatical person in Red Flag entries (second-person "You should..." vs third-person "The skill should..." vs imperative "Stop and..."). Report counts; suggest a convention (typically second-person imperative for direct addressee).

- **Archetype concentration.** Count archetype distribution. If any single archetype is > 80% of the audited set and the user expected diversity, flag explicitly. (Concentration is not inherently bad; it's flagged only when surprising.)

- **Pattern-coverage gaps.** For each pattern, count how many skills have it `absent`. If a pattern is `absent` in > 70% of skills, surface as a fleet-wide gap. Two interpretations: either the fleet under-applies the pattern, or the catalog over-prescribes it. Let the user decide.

- **Versioning drift.** Count skills with `version: 0.0.0`, missing `version`, or non-semver values. List them.

- **`allowed-tools` sprawl.** Compute the union of tools across all skills. Flag any skill whose `allowed-tools` is more than 1.5× the set median — suggests an over-permissive frontmatter.

These findings are advisory, not blocking. They inform a follow-up `modernize` campaign or a fleet-wide convention decision; the user picks which to act on.

---

## 8. Refresh-specific dispatch notes

- **One research agent per canonical source.** Sources are listed in `rules/research-sources.md`.
- Each agent fetches via `WebFetch` for known URLs, `WebSearch` for query-driven sources.
- Each agent returns structured `ResearchFinding[]` (see `references/state-schema.md` § `RefreshPlan`):
  ```json
  {
    "patternId": 3,                        // existing pattern impacted, or null for new
    "kind": "new-pattern | updated-detection | deprecated-pattern | rubric-shift",
    "description": "<one paragraph>",
    "evidenceUrls": ["<url>", "..."]
  }
  ```
- Aggregator deduplicates findings by `(patternId, kind, description-hash)`.
- **Conflicts** surface explicitly: when two sources make incompatible claims about the same pattern, the aggregator emits a `ConflictFinding` rather than picking a winner. The user resolves at the diff-preview gate.
- Source confidence: a finding corroborated by 2+ canonical sources is marked higher confidence in the diff preview than a finding from a single source.

---

## 9. Pressure-test-specific dispatch notes

- **Only fan out when scenarios are independent.** Independence is a property of the scenario, not a runtime decision. The scenario catalog (`rules/scenario-catalog.md`) marks each scenario as `independent` or `setup-dependent`.
- **`independent` scenarios** can run in parallel. Examples: "frontmatter validity", "decision graph parses", "Red Flags count ≥ 4", "self-test scenarios load", "allowed-tools non-empty". Each constructs and tears down its own state.
- **`setup-dependent` scenarios** run serially in the order the catalog specifies. Examples: "post-modernize state passes audit" depends on "modernize completes successfully"; "history JSONL append" depends on prior audit run.
- The pressure-test driver:
  1. Partitions scenarios into `independent` and `setup-dependent` groups.
  2. Fans out the `independent` group with the dispatch primitive (one scenario per agent).
  3. Runs the `setup-dependent` group serially after the parallel group completes.
  4. Aggregates results; computes `overall: PASS | FAIL` (PASS only when every RED scenario is PASS).
- Per-scenario timeout default: 120 seconds. Configurable via the calling subcommand.

When in doubt about whether a scenario is independent, mark it `setup-dependent` and run it serially. False negatives (running an independent scenario serially) cost time but never correctness; false positives (running a dependent scenario in parallel) cause flaky pressure-tests, which are worse than slow ones.

---

## 10. Anti-patterns to avoid

- **Nested fan-out.** A dispatched agent spawning further agents. Compounds context cost and obscures failure attribution. Always leaf-only.
- **Shared mutable state.** Two agents writing to the same path or appending to the same JSONL. Race conditions; data loss. The parent owns all writes.
- **Unbounded concurrency.** Skipping the `--parallelism` cap "because the machine is fast." Saturates context budgets and triggers timeouts.
- **Silent unit drop.** Treating a failed batch as if its units never existed. Always surface failed batches in the report — see `audit-all.md` § Aggregation rules.
- **Aggregator inside an agent.** Asking one agent to compute cross-cutting findings over another agent's output. Cross-cutting findings live in the parent.
- **Forced parallelism on dependent work.** Running setup-dependent scenarios in parallel "because it's faster." Causes flakiness; the time saved is dwarfed by debugging time.

---

## Summary

Fan out for independence + scale. Batch when units are small. Cap concurrency to respect harness and machine. Use a strict prompt template — read-only, no nesting, JSON-only output. Aggregate with explicit handling for failures: mark, never drop. Cross-cutting findings live in the aggregator, not in agents.
