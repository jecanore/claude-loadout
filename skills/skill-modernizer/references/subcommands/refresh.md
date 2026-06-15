# `refresh` — research current best practices and update the pattern catalog

**Loads on entry:**
- `rules/research-sources.md`
- `rules/parallel-dispatch.md`
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `references/state-schema.md`
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, mutating

---

## Workflow

```
RESEARCH (parallel) → AGGREGATE → DIFF → GATE → APPLY → VERIFY
```

`refresh` is the only subcommand authorized to mutate `rules/pattern-catalog.md`, `rules/scoring-rubric.md`, and `rules/research-sources.md`. Every mutation is gated on explicit user approval after a full diff preview.

---

## Steps

1. **Pre-gate.**
   - Verify `skill-modernizer`'s own directory is writable.
   - Verify no in-progress git operation in the skill's repo (if it has one).
   - Detect optional composers (`Remote_Skill_Security_Check`); offer install if absent and any source surfaces third-party skills as examples.

2. **Tool capability check.**
   - Inspect this skill's `SKILL.md` frontmatter for `WebFetch` and `WebSearch` in `allowed-tools`.
   - If neither is present, switch to **manual-research mode** (see below) and SKIP to step 11.
   - If only one is present, log a warning and proceed; some sources may degrade.

3. **Load the source catalog.**
   - Read `rules/research-sources.md`.
   - Filter out entries marked `deprecated: true`.
   - Group remaining entries by `priority` (primary first).

4. **Snapshot current catalog state.**
   - Compute and stash the sha256 hashes of `rules/pattern-catalog.md` and `rules/scoring-rubric.md`.
   - These hashes anchor the diff and let VERIFY confirm the apply touched only intended files.

5. **Plan the dispatch.**
   - Compute per-batch parallelism per `rules/parallel-dispatch.md`.
   - One agent per source (or one per batch when sources share a host and rate limits matter).
   - Announce the plan: number of agents, sources covered, expected duration.

6. **Snapshot to backup directory.**
   - Snapshot `rules/pattern-catalog.md`, `rules/scoring-rubric.md`, and `rules/research-sources.md` to:
     ```
     $CLAUDE_HOME/.backups/skill-modernizer/skill-modernizer-<ISO-date>/
     ```
   - Append an `unverified` entry to the backup index.

7. **Dispatch research agents.** See `## Research dispatch` below.

8. **Aggregate findings.** See `## Aggregating findings` below.

9. **Resolve conflicts.** See `## Conflict resolution` below.

10. **Compute proposed diff.**
    - Render unified diffs against `rules/pattern-catalog.md`, `rules/scoring-rubric.md`, and `rules/research-sources.md` (the last when source staleness is detected).

11. **Present diff for approval.** See `## Diff preview` and `## Gate semantics`.

12. **On approval: apply edits.**
    - Apply via Edit/Write atomic operations. One edit per file, never partial-write.
    - Bump this skill's `version` per `## Version bump policy`.
    - Append a `refresh` event to audit history JSONL.

13. **Self-audit.** See `## Self-audit after apply`.

14. **Mark backup as verified** and emit the report.

---

## Research dispatch

Delegate to `rules/parallel-dispatch.md` for the fan-out. Each agent receives:

- The source entry (name, url, kind, priority, query_strategy).
- The current `rules/pattern-catalog.md` for context.
- A return-shape contract: `ResearchFinding[]` per `references/state-schema.md`.

Per-agent task per `query_strategy`:

| Strategy | Action |
|---|---|
| `fetch-and-parse` | WebFetch the URL; parse for skill-authoring guidance; extract pattern-relevant claims. |
| `keyword-search` | WebSearch with seeded queries (`"agent skill" pattern`, `SKILL.md best practice`, `skill rationalization`); fetch top-N results. |
| `recent-releases` | For repo sources, list releases / recent commits; surface changes to skill structure conventions. |

Each agent must return:
- `findings`: array of `ResearchFinding` entries (new pattern, updated detection, deprecated pattern, rubric shift).
- `evidence_urls`: at least one URL per finding.
- `source_health`: `ok | redirected | 404 | content-mismatch`. Drives staleness detection in step 4 of `## Diff preview`.

Agents that fail (timeout, 5xx, parse error) return `source_health: "failed"` with an empty findings array. Failed sources are aggregated as warnings, never silently dropped.

---

## Aggregating findings

After all agents return:

1. **Bucket by `kind`:** `new-pattern`, `updated-detection`, `deprecated-pattern`, `rubric-shift`.
2. **Deduplicate:** when two sources surface the same finding, merge them into one finding with combined `evidence_urls`.
3. **Score evidence weight:** count primary-source evidence vs. secondary; primary outweighs secondary on conflicts.
4. **Track novelty:** mark findings that don't map to any existing pattern in `rules/pattern-catalog.md` as `new-pattern` candidates.

Output is a single `RefreshPlan.findings[]` per `references/state-schema.md`.

---

## Conflict resolution

When two sources disagree on a finding (e.g., one deprecates a pattern, another adds detail to it):

1. **Apply the source-priority rule from `rules/research-sources.md`:** primary outweighs secondary.
2. **Within the same priority,** more-recent finding outweighs older. Use the source's last-modified or release date when available; otherwise use the agent's `fetched_at`.
3. **If still ambiguous,** record the conflict in `RefreshPlan.conflicts[]`. The diff preview surfaces it explicitly to the user — never pick arbitrarily.

A surfaced conflict blocks auto-apply for the affected pattern; the user must adjudicate before that pattern's edit applies. Other findings can still apply if approved.

---

## Diff preview

Render the **full** unified diff for every file `refresh` would touch. Do not summarize. Order:

1. `rules/pattern-catalog.md`
2. `rules/scoring-rubric.md`
3. `rules/research-sources.md` (only when source staleness was detected)

Diff format:

```diff
--- rules/pattern-catalog.md
+++ rules/pattern-catalog.md (proposed)
@@ -120,3 +120,18 @@
 ### 10. Provides / Consumes composability
 ...
+
+### 11. <new pattern name>
+
+**Intent:** ...
+
+**Detection:** ...
```

After the diff, render:

- A bullet list of findings keyed to diff hunks (`hunk #1 — pattern-catalog.md +123 — adds pattern 11`).
- A bullet list of conflicts (if any), with the two competing claims and source names.
- The proposed version bump (e.g., `0.3.0 → 0.4.0` minor for additive change).

---

## Gate semantics

After the diff preview, ask the user one of:

- `apply all` — apply every hunk; resolve any unresolved conflicts by deferring those hunks.
- `apply hunks <list>` — apply only the listed hunks; defer the rest (deferred hunks still appear in the next refresh).
- `cancel` — discard the plan; leave files unchanged. Backup is kept (`unverified`) and pruned per the standard TTL.

The gate is **explicit text approval**. Never proceed on silence, on partial responses, or on inferred consent. If the user's response is ambiguous, re-ask.

If WebFetch/WebSearch are unavailable (manual-research mode), the gate is replaced by the instruction in `## What refresh never does` — no edits apply automatically.

---

## Self-audit after apply

After apply succeeds, run `audit` on `skill-modernizer` itself.

- Target path: this skill's own directory.
- Expected: overall grade `A` (the skill that codifies the patterns must satisfy them).
- If grade dropped to `B` or lower: surface the regression. Do not auto-revert; the user decides whether to roll back or to update this skill to satisfy the new pattern.
- Append the self-audit grade to the refresh history entry.

This is "eat your own dog food" — every change to the catalog is validated against the skill that defines it.

---

## Version bump policy

Version field lives in this skill's `SKILL.md` frontmatter (`version:`).

| Change kind | Bump |
|---|---|
| New pattern added (additive) | minor (`0.3.0 → 0.4.0`) |
| Detection regex updated (non-breaking) | patch (`0.3.0 → 0.3.1`) |
| Pattern deprecated (removal scheduled) | minor |
| Pattern removed entirely | major |
| Rubric weights shifted (changes letter grades) | minor |
| Source list updated (add/remove/fix-url) | patch |
| Wording-only clarifications | patch |

When a single refresh applies multiple kinds at once, take the most-significant bump.

Apply the bump to `SKILL.md` frontmatter as part of the same atomic edit that mutates the rules files.

---

## Report format

### Default (human-readable)

```
Refresh — skill-modernizer
Version: 0.3.0 → 0.4.0
Date:    <ISO-timestamp>

Sources queried (8)
─────────────────────
 1  anthropic-skills-docs           ok      4 findings
 2  anthropics-skills-repo          ok      2 findings
 3  superpowers-repo                ok      1 finding
 4  anthropic-engineering-blog      ok      0 findings
 5  community-skill-repo-a          ok      1 finding
 6  community-skill-repo-b          failed  -
 ...

Findings (8)
────────────
 + new-pattern         pattern 11 — Skill discovery announcement
 ~ updated-detection   pattern 2  — Red Flags threshold raised to 5
 - deprecated-pattern  pattern 6  — Rigid/Flexible (subsumed by archetype)
 ...

Conflicts (1)
─────────────
 ! pattern 9 self-test rigor — primary docs say 5 scenarios, community says 7
   (recommended: 5; surfaced for user adjudication)

Apply (after gate):
  rules/pattern-catalog.md      +28 -3
  rules/scoring-rubric.md       +6  -1
  rules/research-sources.md     +2  -0  (source-c last-verified refreshed)

Self-audit (post-apply): A (no regression)
```

### `--json`

Schema in `rules/json-schema.md` (`refresh` schema). Top-level keys:

```json
{
  "tool_version_before": "0.3.0",
  "tool_version_after": "0.4.0",
  "sources_queried": [ /* ResearchSource[] */ ],
  "findings": [ /* ResearchFinding[] */ ],
  "conflicts": [ /* ConflictFinding[] */ ],
  "approved": true,
  "self_audit_grade_after": "A"
}
```

---

## Cadence guidance

`refresh` is user-driven. Recommended cadence:

- **Monthly** is reasonable for active ecosystems — catches drift before it compounds.
- **Quarterly** is fine for stable ecosystems — fewer findings, lower noise.
- After any major announcement (new SDK release, new official skills repo conventions), run an out-of-cycle refresh.

`refresh` is idempotent: running it twice in a row should produce zero findings the second time, modulo source-content updates between runs.

---

## Manual-research mode

When `WebFetch` and `WebSearch` are not in this skill's `allowed-tools`:

1. Emit the URL list from `rules/research-sources.md` to the user.
2. Provide instructions for each source: what to read, what to extract, what shape to return.
3. Ask the user to either:
   - **Add the tools** to this skill's `SKILL.md` frontmatter `allowed-tools` and re-run `refresh`, or
   - **Run refresh manually** with the URL list and paste structured findings back.
4. Skip the dispatch, aggregate, diff, gate, apply, and self-audit steps. The session ends with the URL list emitted.

No edits apply in manual-research mode.

---

## Source-list maintenance (meta-instruction)

`refresh` also audits `rules/research-sources.md` itself.

- Sources returning `404`, `redirected`, or `content-mismatch` for two consecutive refreshes are candidates for deprecation.
- The diff preview includes proposed edits to `rules/research-sources.md` when stale sources are detected:
  - Mark stale source `deprecated: true` with a `deprecated_reason`.
  - Update `last_verified` for healthy sources.
- The user can approve the source-list edit independently of the catalog edit.

This is the meta-instruction: the source list is itself a moving target, and `refresh` is the only mechanism that keeps it current.

---

## What `refresh` never does

- Never mutates `rules/pattern-catalog.md`, `rules/scoring-rubric.md`, or `rules/research-sources.md` without explicit user approval after a full diff preview.
- Never picks arbitrarily on conflicts — surfaces them for adjudication.
- Never silently drops failed-agent results — they appear as warnings.
- Never installs composer skills (`Remote_Skill_Security_Check`, etc.) without explicit approval.
- Never bumps version unless an edit was applied.
- Never auto-deletes a source from `rules/research-sources.md` — only deprecates with a reason. Deletion is a manual-edit operation.
- Never runs in a plugin-cache install of `skill-modernizer`. Cache copies are managed by the plugin loader; mutations would be blown away.
- Never skips the self-audit step. Eating own dog food is non-negotiable.
