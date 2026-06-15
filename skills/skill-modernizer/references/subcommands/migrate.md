# `migrate <path>` — convert a legacy monolithic skill to current archetype layout

**Loads on entry:**
- `rules/pattern-catalog.md`
- `rules/scoring-rubric.md`
- `rules/migration-map.md`
- `rules/edit-strategies.md`
- `references/state-schema.md`
- `rules/script-hygiene.md` (only if target has `scripts/`)
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, mutating

---

## Workflow

```
BACKUP → DETECT → PLAN → DIFF-PREVIEW → GATE → APPLY → VERIFY
```

`migrate` is the structural sibling of `modernize`. Where `modernize` adds
patterns to a skill that already has the modern shape, `migrate` reshapes a
legacy monolithic skill into the split archetype: SKILL.md as orchestrator,
deep content extracted into `references/`, modern frontmatter keys added.

This is the riskiest mutating subcommand. v1 is conservative by design:
**preserve every line of original content**. Never silently drop "obviously
redundant" sections — the Rationalization Defense in SKILL.md addresses this
exact temptation.

---

## Steps

Create one TodoWrite item per step before any work begins. Atomic, never
batched.

1. **Pre-gate.**
   - Resolve `<path>`, verify directory and `SKILL.md` presence.
   - Refuse plugin-cache paths (`*/plugins/cache/*`). Suggest copy-first.
   - If the target sits in a git repo mid-merge or mid-rebase, STOP.

2. **Detect optional composers** (same flow as `modernize`).

3. **Detect "legacy" indicators.**
   Apply the detection rules in `rules/migration-map.md`. Common signals:
   - `SKILL.md` exceeds **500 lines**.
   - No `references/` directory exists.
   - Frontmatter lacks `version:`.
   - Frontmatter uses legacy keys (`tools:`, `triggers:`, `name` only) instead
     of the current set (`allowed-tools:`, `description:`, `version:`).
   - Embedded subcommand handlers as headings in SKILL.md instead of
     `references/subcommands/<name>.md` files.

   If **none** of the legacy indicators fire, report "skill is already in
   current shape" and suggest `modernize` instead. Exit cleanly.

4. **Snapshot to backup.**
   - Same backup module as `modernize`. The backup is the safety net for the
     full structural change.
   - Index entry is `unverified` until post-apply verification passes.

5. **Compute the migration plan.**
   - For each legacy indicator that fired, look up the conversion rule in
     `rules/migration-map.md`.
   - The plan is a sequence of `ProposedEdit` objects (see
     `references/state-schema.md`):
     - `extract-to-reference` — pull a long inline section into a new
       `references/<name>.md` file. SKILL.md keeps a one-line pointer.
     - `split-monolith` — for embedded subcommand handlers, create
       `references/subcommands/<name>.md` per detected handler and replace
       the inline handler with a one-line reference in SKILL.md's routing
       table.
     - `add-frontmatter-key` — add modern keys (`version:`, `allowed-tools:`).
       Migrate legacy keys per the migration map; keep originals as comments
       inside the frontmatter for one release cycle.
     - `replace-section` — only when the original section's structure is
       incompatible with the new archetype. Original content is preserved in
       the target via an `extract-to-reference` step earlier in the plan.
   - **Never plan a deletion.** If a section appears redundant, route it to
     `references/_legacy/<topic>.md` with a disclaimer header rather than
     dropping it. The user can prune manually after review.

6. **Render the unified diff.**
   - Same diff renderer as `modernize`. New files (`references/...`) are
     diffed against the empty file so additions are fully visible.
   - The diff is grouped by file; new files appear first, modified files
     after, in the order they will be applied.
   - For large legacy files, the diff will frequently exceed 500 lines. The
     summary mode is appropriate; the gate prompt names every new file.

7. **Show the diff and GATE.**
   - Same gate semantics as `modernize`. Explicit `y` required.
   - The gate prompt always names:
     - Every new file path.
     - Every section in SKILL.md that will be replaced by a pointer.
     - The frontmatter key changes (added, renamed, retained-as-comment).
     - The proposed major version (`<old> → 1.0.0` if `<old>` is `0.x.y`,
       otherwise `<old-major+1>.0.0`).

8. **Apply.**
   - Create new `references/` files first (additive, no risk).
   - Then mutate SKILL.md to insert pointers and adjust frontmatter.
   - Each step is atomic Edit/Write. Halt and surface on tool error.

9. **Re-run `audit` against the post-migration state.**
   - The migrated skill should land at grade B or better on the new
     archetype. A grade below B is a flag, not a hard error — surface it and
     suggest a `modernize` follow-up to address residual `partial` patterns.

10. **Bump frontmatter `version:` (major).**
    - `0.x.y → 1.0.0` (the most common legacy case).
    - For skills already at `1.x.y` or higher, `<n>.<x>.<y> → <n+1>.0.0`.
    - The major bump signals a structural breaking change. Downstream
      consumers that pinned the previous version will see the bump.

11. **Append history entry** with `action: "migrate"`.

12. **Mark backup verified.**

13. **Emit report.**

---

## Edit strategies

Migration leans on `rules/migration-map.md` for *what to convert* and
`rules/edit-strategies.md` for *how to write the new sections*. The two are
distinct:

- `rules/migration-map.md` answers: "this legacy section heading X belongs in
  reference file Y."
- `rules/edit-strategies.md` answers: "when adding pattern Z, here is the
  recipe."

`migrate` invokes both. Conversion happens first (preserve everything by
relocating). Then, optionally, `migrate` will plan the missing-pattern edits
that `modernize` would also plan — but **only if the user requests** by
passing `--with-modernize`. Without that flag, `migrate` is purely
structural; missing patterns are reported but not auto-fixed.

---

## Diff preview

Same renderer as `modernize`. Migration diffs are typically large because
content moves between files. Display rules:

- Always print the list of new files in full.
- Always print frontmatter changes in full.
- For SKILL.md and large extracted references, default to summary mode when
  the diff exceeds 500 lines, with full diff available on request.

A migration that does not appear to add any new files is suspicious — surface
this as a planning warning and ask the user whether to proceed.

---

## Gate semantics

Same explicit-approval gate as `modernize`. Until the user types `y`, no file
on disk is changed beyond the backup snapshot.

**Decline path:** No edits applied. Backup remains. Append a `declined`
annotation line to the index. Exit zero.

**Apply-time error path:** The backup is the recovery contract. `migrate`
reports the partial state and stops. Do not auto-revert.

The conservative posture is intentional. Migration changes file layout; an
auto-revert that miscompares could leave the skill in a worse state than
either the original or the partial-applied state.

---

## Re-audit after apply

Mandatory. The re-audit runs against the new archetype:

- The detected archetype after migration may differ from before. A monolithic
  legacy skill with embedded handlers usually lands as
  `orchestrator-with-subcommands` after split.
- The post-migration grade is what gets recorded in history JSONL.
- A grade below the pre-migration grade is a regression and is surfaced
  prominently. Do not proceed silently. The user may choose to inspect the
  diff and the backup before committing further changes.

---

## Version bump policy

`migrate` always bumps the **major** position. Structural reshape is a
breaking change for any consumer that pinned the old version.

| Before | After |
|---|---|
| `0.1.0` | `1.0.0` |
| `0.9.4` | `1.0.0` |
| `1.5.7` | `2.0.0` |
| `3.0.0` | `4.0.0` |

If the frontmatter has no `version:` key (very legacy), `migrate` adds it at
`1.0.0` as part of the frontmatter migration step.

---

## Backup integration

Same module as `modernize`:

- Snapshot to `$CLAUDE_HOME/.backups/skill-modernizer/<skill-name>-<ISO-date>/`.
- `unverified` index line written before any edit.
- `verified` line appended after post-migrate re-audit succeeds.
- Index is append-only.

Migration backups are particularly important because the archetype changes;
the backup is the only path back to the legacy shape if the user dislikes
the conversion.

---

## Report format (default, human-readable)

```
migrate: <name> (v<old> → v<new>) — archetype <old-archetype> → <new-archetype>
Path:   <absolute-path>
Date:   <ISO>
Backup: <absolute-backup-path> [verified]

Structural changes
──────────────────
 + references/subcommands/<sub>.md         (extracted from SKILL.md heading)
 + references/<topic>.md                   (extracted from SKILL.md prose)
 ~ SKILL.md                                 (-N lines extracted, +M pointers)
 ~ frontmatter: + version, + allowed-tools, ~ description

Pre-migration audit:  <grade>
Post-migration audit: <grade>

Recommended next step
─────────────────────
- run `modernize` to address residual `partial` patterns:
  <list>
```

When `--with-modernize` was passed, the recommended-next-step block is
replaced with the modernize recipe summary.

---

## Report format (with `--json`)

Schema in `rules/json-schema.md`. Top level:

```json
{
  "version": "1.0",
  "subcommand": "migrate",
  "skill": "<name>",
  "path": "<absolute-path>",
  "version_before": "<semver>",
  "version_after": "<semver>",
  "archetype_before": "<arch>",
  "archetype_after": "<arch>",
  "grade_before": "F",
  "grade_after": "B",
  "extracted_files": ["references/..."],
  "frontmatter_changes": {"added": [...], "renamed": [...], "kept_as_comment": [...]},
  "backup": {"path": "<abs>", "status": "verified"},
  "with_modernize": false
}
```

---

## What `migrate` never does

- Never deletes content. Sections that appear redundant are relocated to
  `references/_legacy/<topic>.md` with a disclaimer header. The user prunes
  manually after review.
- Never collapses two sections into one without an explicit user instruction.
- Never edits a skill inside a plugin-cache directory.
- Never proceeds without a backup.
- Never bumps the version below the major position. Patch and minor bumps
  belong to `modernize`.
- Never auto-runs `modernize` after migrating unless `--with-modernize` was
  explicitly passed.
- Never installs an optional composer without explicit approval.
- Never mutates the backup index in place. Append-only.
- Never stages or commits anything in the target's git repo.
- Never assumes the post-migration archetype matches the pre-migration
  archetype; it re-detects from the migrated source.
