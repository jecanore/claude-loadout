# `modernize <path>` — bring a skill up to current standards

**Loads on entry:**
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `rules/edit-strategies.md`
- `references/state-schema.md`
- `rules/script-hygiene.md` (only if target has `scripts/`)
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, mutating

---

## Workflow

```
BACKUP → AUDIT → PLAN → DIFF-PREVIEW → GATE → APPLY → VERIFY
```

Every phase is mandatory. No phase may be skipped, even when the prior phase
result feels obvious. The gate is the only place where a human decides; every
other phase is mechanical.

---

## Steps

Create one TodoWrite item per step before any work begins. Mark `in_progress`
on entry, `completed` immediately on exit. No batching.

1. **Pre-gate.**
   - Resolve `<path>` to an absolute directory.
   - STOP if the directory does not exist.
   - STOP if `SKILL.md` is missing at the root.
   - STOP if the path matches any plugin-cache directory pattern
     (`*/plugins/cache/*`). Cache directories are owned by the plugin manager;
     mutation is forbidden. Suggest: copy the skill into a personal skills
     directory first, then re-run `modernize` against the copy.
   - If the target sits inside a git repository, STOP when the repo is mid-merge
     or mid-rebase (`.git/MERGE_HEAD` or `.git/rebase-merge` present). Surface
     the state and ask the user to resolve before retrying.

2. **Detect optional composers.**
   - Probe for `superpowers:writing-skills` and `Remote_Skill_Security_Check`
     using the SKILL.md detection block.
   - If a recommended composer is missing, OFFER install. On decline, set
     `reducedRigor=true` and continue. On `abort`, stop cleanly with no edits.

3. **Run `audit` against the target.**
   - Reuse the read-only audit pipeline. Do not synthesize findings; the audit
     output is the input to planning.
   - When the audit yields grade `A` and zero `partial`/`absent` patterns,
     report "already modern" and exit cleanly. Do not invent edits.

4. **Snapshot to backup.**
   - Invoke the backup module (see `## Backup integration` below) before any
     edit is computed.
   - Append an `unverified` index entry. Edits cannot apply until this step
     succeeds.

5. **Compute proposed edits.**
   - For each `partial` and `absent` pattern in the audit, look up the recipe
     in `rules/edit-strategies.md`.
   - Each recipe yields one or more `ProposedEdit` objects (see
     `references/state-schema.md`). Recipes never silently delete content.
   - When a recipe needs information the auditor cannot infer (e.g., user-
     specific self-test scenarios), use `AskUserQuestion`. Do not fabricate.

6. **Render the unified diff.**
   - Concatenate per-file diffs in `current → proposed` order. Headers identify
     each affected file by its absolute path.
   - If a recipe creates a new file, render the diff against the empty file so
     the addition is fully visible.
   - If a recipe would delete content (rare; only when the user asked), the
     deletion is marked with a `# DELETION` banner above the affected hunk.
     The gate prompt names every deletion explicitly.

7. **Show the diff and GATE.**
   - Present the diff to the user. See `## Gate semantics` and
     `## Diff preview` for the exact behavior.
   - Wait for explicit approval. No approval, no edits.

8. **Apply.**
   - Execute edits via Edit/Write atomic operations, one file at a time.
   - On any tool error, STOP and surface the partial state. Do not retry
     silently. The backup snapshot is the recovery path.

9. **Re-run `audit` against the post-apply state.**
   - The post-apply audit is mandatory. It is the verification that the edits
     achieved their intent.
   - Compare pre/post grades; surface any pattern that did not improve.

10. **Bump frontmatter `version:` (minor).**
    - `0.1.0 → 0.2.0`, `1.4.7 → 1.5.0`, etc. Patch position resets to `0`.
    - Edit `version:` in place; do not rewrite the rest of the frontmatter.

11. **Append history entry.**
    - One JSONL line to `<config>/.skill-modernizer/history.jsonl` with
      `action: "modernize"`, the new version, and the post-apply grade.

12. **Mark backup verified.**
    - Append a new index line with `status: "verified"` for the same backup
      path. Never mutate the prior `unverified` line; the index is append-only.

13. **Emit report.**

---

## Edit strategies

Per-pattern edit recipes live in `rules/edit-strategies.md`. Each recipe
provides:

- The edit kind (`add-section`, `replace-section`, `extract-to-reference`,
  `add-frontmatter-key`, `split-monolith`).
- The target location in the skill's source files.
- Diff anchors (regexes that locate the insertion point robustly).
- Common pitfalls.

`modernize` reads the catalog and dispatches one recipe per `partial` or
`absent` finding. Recipes that touch the same anchor are merged into a single
`ProposedEdit` to keep the diff coherent.

When two recipes conflict (e.g., one wants to insert `## Red Flags` after
frontmatter; another wants to insert `## Decision graph` in the same slot),
the order in `pattern-catalog.md` is the tiebreaker — earlier patterns win
the higher slot.

---

## Diff preview

The unified diff is computed from the proposed `ProposedEdit` set:

- Each edit names the target file and the `before` / `after` content blocks.
- A standard unified diff is generated with three lines of context.
- The diff is grouped by file. Within a file, hunks appear top-down.

**Display rules:**

- Total diff ≤ 500 lines: print in full.
- Total diff > 500 lines: print a summary first (one line per affected file
  with `+adds / -dels`), then ask `Show full diff? [y/n]`. On `y`, print
  in full. On `n`, the gate prompt names the affected files and the user
  decides without seeing every line. Approval is still explicit.

**Always shown, regardless of size:**

- Every file that will be created.
- Every file that will be deleted (annotated with `# DELETION`).
- Every frontmatter key that will be added, removed, or changed.

A summary mode never hides a deletion or a new file. Those are loud by design.

---

## Gate semantics

The gate is the single human checkpoint. Until the user approves, no file on
disk has changed beyond the backup snapshot.

**Prompt format (default):**

```
modernize plan for <skill-name> (v<old> → v<new>)
  files affected: N (M new, K modified, 0 deleted)
  patterns satisfied: <list>
  unified diff: <see above>

Apply? [y/n]
```

**Approval:** Only an explicit `y` (or `yes`) advances. Any other response
aborts cleanly.

**Decline path:**

- No edits have applied — the backup snapshot is the entire state.
- Mark the `unverified` backup index entry with a `declined` annotation by
  appending a new line (still append-only) so the prune pass can collect
  declined snapshots after the standard `unverified` TTL.
- Exit zero. The user keeps the backup; nothing in the target changed.

**No partial-state rollback is needed because edits do not apply until after
the gate.** If a tool error occurs mid-apply (after the gate), the backup
snapshot is the documented recovery path; `modernize` reports the partial
state and exits non-zero.

---

## Re-audit after apply

The re-audit is non-negotiable. It runs the full audit pipeline against the
post-apply state.

- Reuse the audit checklist; do not shortcut to "compare findings".
- A re-audit failure (any pattern that was supposed to be fixed but is still
  `absent` or `partial`) is reported in the final output. The skill is left
  in its post-apply state — the edits stand — but the report flags the gap.
- The re-audit grade is what gets written to history JSONL, not the planning
  audit grade. History reflects observed reality.

If the re-audit grade is **lower** than the pre-audit grade, surface this
prominently in the final report ("regression detected: <patterns>") and
recommend the user inspect the diff and the backup. Do not auto-revert; the
user gated the changes and may want to inspect manually.

---

## Version bump policy

`modernize` bumps the **minor** position of `version:` in the target's
frontmatter:

| Before | After |
|---|---|
| `0.1.0` | `0.2.0` |
| `1.4.7` | `1.5.0` |
| `2.0.0` | `2.1.0` |

Patch resets to `0`. Major position is untouched. If the frontmatter has no
`version:` key (legacy skill), `modernize` does **not** add one; that is
`migrate`'s job. Modernize on a legacy skill flags this in the report and
suggests `migrate` first.

---

## Backup integration

Every mutating subcommand snapshots before any edit is computed. The order is
strict: backup, then plan, then diff, then gate, then apply.

**Snapshot location** (always outside the skills namespace so the snapshot
never registers as a discoverable skill):

```
$CLAUDE_HOME/.backups/skill-modernizer/<skill-name>-<ISO-date>/
```

Where `$CLAUDE_HOME` resolves to the user's Claude config directory. The
snapshot mirrors the target tree exactly: every file under the skill root is
copied, preserving structure.

**Index entry** (append to `$CLAUDE_HOME/.backups/skill-modernizer/index.jsonl`):

```jsonl
{"ts":"<ISO-timestamp>","skill":"<name>","subcommand":"modernize","ver":"<old-semver>","path":"<backup-dir>","status":"unverified"}
```

After the post-apply re-audit succeeds, append a second line for the same
backup path:

```jsonl
{"ts":"<ISO-timestamp>","skill":"<name>","subcommand":"modernize","ver":"<old-semver>","path":"<backup-dir>","status":"verified"}
```

Never mutate prior lines. The index is append-only forever.

**Pre-flight check:** if disk-write to the backup location fails, STOP. Do not
proceed without a snapshot.

---

## Report format (default, human-readable)

```
modernize: <name> (v<old> → v<new>) — <pre-grade> → <post-grade>
Path:   <absolute-path>
Date:   <ISO>
Backup: <absolute-backup-path> [verified]

Patterns addressed
──────────────────
 #  Pattern                     Before    After   Action
 2  Red Flags                   ~ (C)     ✓ (A)   added 4 entries
 3  Rationalization Defense     ✗ (F)     ✓ (A)   added section
 9  Self-test                   ✗ (F)     ✓ (A)   created references/skill-self-test.md

Files changed
─────────────
 + references/skill-self-test.md           (new)
 ~ SKILL.md                                 (+42 / -3)

History
───────
 prior audits: <last 3 entries>
 this run:     modernize, post-grade <letter>
```

Add a `regression detected:` block above `Patterns addressed` when the post-
audit reveals any unimproved pattern.

---

## Report format (with `--json`)

Schema in `rules/json-schema.md`. Top level:

```json
{
  "version": "1.0",
  "subcommand": "modernize",
  "skill": "<name>",
  "path": "<absolute-path>",
  "version_before": "<semver>",
  "version_after": "<semver>",
  "grade_before": "C",
  "grade_after": "A",
  "edits": [...],
  "backup": {"path": "<abs>", "status": "verified"},
  "regressions": []
}
```

The `edits` array contains one entry per `ProposedEdit` actually applied,
including the recipe id from `rules/edit-strategies.md` for traceability.

---

## What `modernize` never does

- Never deletes content silently. Any deletion appears in the diff with an
  explicit `# DELETION` banner and is named in the gate prompt. If the user
  did not approve a deletion, it does not happen.
- Never edits a skill inside a plugin-cache directory. Refuse with a
  copy-first suggestion.
- Never edits a skill whose host repo is mid-merge or mid-rebase.
- Never installs an optional composer without explicit approval.
- Never bumps the major version. Major bumps belong to `migrate`.
- Never adds a `version:` key to a frontmatter that lacks one. That is
  structural; route the user to `migrate`.
- Never skips the post-apply re-audit, even when the diff was small.
- Never mutates the backup index in place. Append-only is the rule.
- Never auto-reverts on regression. Surfaces the regression and lets the user
  decide.
- Never stages or commits anything in the target's git repo. The user owns
  staging.
