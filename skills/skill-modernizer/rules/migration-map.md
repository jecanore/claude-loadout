# Migration Map — Legacy SKILL.md → current archetype layout

**Loaded by:** `migrate`

**Version:** 1.0

---

## Purpose

This file specifies how `migrate` converts a legacy monolithic skill into the
current split layout. It answers two questions:

1. **What does "legacy" look like?** Detection patterns.
2. **Where does each legacy section belong in the new layout?** Per-pattern
   split rules.

Conservative posture: **preserve everything**. Sections that appear redundant
relocate to `references/_legacy/<topic>.md` with a disclaimer header rather
than disappear. The user prunes manually after review.

---

## Legacy detection patterns

A target is considered legacy when **any** of the following indicators fire.
Multiple indicators are common; one is sufficient.

| Indicator | How detected | Severity |
|---|---|---|
| `SKILL.md` exceeds 500 lines              | line count | strong |
| No `references/` directory                | filesystem | strong |
| Frontmatter lacks `version:`              | YAML parse | strong |
| Frontmatter uses `tools:` (legacy key)    | YAML parse | medium |
| Frontmatter uses `triggers:` (legacy key) | YAML parse | medium |
| Frontmatter is bare (only `name:`)        | YAML parse | strong |
| Embedded subcommand handlers as headings  | regex on body | strong |
| Decision graph absent and body > 300 lines| regex + count | medium |
| Inline scenario list as a heading-2 block | regex on body | medium |
| Inline archetype templates pasted in body | regex on body | medium |
| No rule loading map                       | regex on body | weak |

**Strong** indicators alone justify migration. **Medium** indicators in
combination justify migration. **Weak** indicators alone do not — they are
modernize territory.

When the only firing indicators are weak, `migrate` reports "skill does not
require structural migration; consider `modernize` instead" and exits.

---

## Legacy-shape catalog

Common shapes that legacy skills take. The migration plan adapts to whichever
shape(s) the target presents.

### Shape A — single long monolith

- One SKILL.md, often 600-1200 lines.
- No `references/` directory.
- Sections inline: prose, examples, scenario lists, FAQ, rationalia.
- Frontmatter minimal.

**Plan:** extract long sections into `references/<topic>.md`. SKILL.md keeps
pointers. Add modern frontmatter keys.

### Shape B — embedded subcommand handlers

- SKILL.md contains `## Subcommand: foo` (or `## /foo`) headings, each
  followed by 50-200 lines of handler logic.
- No `references/subcommands/` directory.

**Plan:** for each embedded handler, create
`references/subcommands/<name>.md`. Replace inline handlers with one-line
pointers in a routing table. If no routing table exists, create one as part
of the migration plan.

### Shape C — inline scenario / archetype dumps

- SKILL.md has a "Scenarios" section listing 10+ scenarios inline.
- Or: an "Archetype templates" section pasting full file trees.

**Plan:** extract to `rules/scenario-catalog.md` (scenarios) or
`rules/archetypes.md` (archetypes). SKILL.md keeps a pointer. The new files
get their own `Loaded by:` header.

### Shape D — partial split, half-finished

- A `references/` directory exists but contains only one or two files.
- SKILL.md still has long inline sections that should have been extracted.

**Plan:** continue the split. New extractions land in `references/`. The
existing references are inspected for staleness; if their content has
diverged from SKILL.md's inline copy, surface the conflict (do not auto-
merge; ask the user which is authoritative).

### Shape E — legacy frontmatter only, modern body

- Body is already well-shaped (decision graph, Red Flags, etc.).
- Frontmatter still uses legacy keys (`tools:`, `triggers:`, no `version:`).

**Plan:** purely a frontmatter migration. No content moves. Add `version:`,
rename `tools:` → `allowed-tools:`, capture `triggers:` content into the
`description:` field per the modern "Use when…" formula.

---

## Per-section split rules

For each common legacy section heading, this table specifies the destination
in the new layout. Headings are matched case-insensitively; minor variants
are accepted. When a section is referenced in multiple destinations, it
stays in SKILL.md as a pointer with the canonical content extracted.

| Legacy heading (regex)               | Destination                                | Edit kind |
|---|---|---|
| `## (subcommand:?\s*\|/)\S+`         | `references/subcommands/<name>.md`         | split-monolith |
| `## scenarios?\b`                    | `rules/scenario-catalog.md`                | extract-to-reference |
| `## archetype templates?\b`          | `rules/archetypes.md`                      | extract-to-reference |
| `## migration\b`                     | `rules/migration-map.md` (if author guide) | extract-to-reference |
| `## script (hygiene\|conventions)\b` | `rules/script-hygiene.md`                  | extract-to-reference |
| `## state schema\b`                  | `references/state-schema.md`               | extract-to-reference |
| `## (faq\|frequently asked)\b`       | `references/faq.md`                        | extract-to-reference |
| `## examples?\b` (long)              | `references/examples.md`                   | extract-to-reference |
| `## history (notes)?\b`              | `references/_legacy/history.md`            | extract-to-reference |
| `## (changelog\|releases)\b`         | `CHANGELOG.md` (alongside SKILL.md)        | extract-to-reference |
| `## (decision graph\|flow chart)\b`  | stay in SKILL.md (orchestrator essential)  | replace-section if reshape needed |
| `## red flags\b`                     | stay in SKILL.md                           | replace-section |
| `## (pitfalls\|gotchas\|warnings)\b` | stay in SKILL.md, rename to `## Red Flags` | replace-section |
| `## rationalization`                 | stay in SKILL.md                           | replace-section |
| `## (provides\|consumes\|composition)\b` | stay in SKILL.md                       | replace-section |
| `## quick reference\b`               | stay in SKILL.md                           | unchanged |

Sections not on this table that exceed ~1500 characters → extract to
`references/<slugified-heading>.md` with a `Loaded by:` placeholder; the
auditor prompts the user post-migration to wire it into the loading map.

---

## Conflict resolution

When two destinations could legitimately claim the same section:

1. **Prefer preserving in `references/` over deleting.** If neither
   destination is clearly canonical, route to `references/_legacy/<topic>.md`
   with a disclaimer header.
2. **Prefer the more specific destination.** A section titled
   "Subcommand: audit" routes to `references/subcommands/audit.md` even if
   it could also be considered an example.
3. **Prefer keeping orchestrator essentials in SKILL.md.** Decision graph,
   Red Flags, Rationalization, routing, Provides/Consumes never leave
   SKILL.md.
4. **Surface ambiguous cases to the user.** Use `AskUserQuestion` rather
   than guessing. Ambiguity here often signals a section that wants to be
   split into two destinations.

---

## Frontmatter migration table

Map of legacy keys to current keys. Multi-line YAML values are preserved
verbatim during migration; only the key name changes.

| Legacy key         | Current key       | Notes |
|---|---|---|
| `tools:`           | `allowed-tools:`  | preserve list contents verbatim |
| `allowedTools:`    | `allowed-tools:`  | rename camelCase → kebab-case (auditor accepts both, kebab preferred) |
| `triggers:`        | `description:`    | merge trigger phrases into the "Use when…" / "Triggers on…" sentence; do not drop |
| `triggerPhrases:`  | `description:`    | same as `triggers:` |
| `examples:`        | (drop from frontmatter; relocate to `references/examples.md`) | preserve content; only the frontmatter key disappears |
| `category:`        | (drop)            | not part of current frontmatter; capture in description if meaningful |
| `tags:`            | (drop)            | same as category |
| `author:`          | preserve as-is    | not strictly required but harmless |
| `license:`         | preserve as-is    | recommended for publishability |
| (no `version:`)    | add `version:`    | start at `1.0.0` per `migrate`'s major-bump policy |
| (no `description:`)| add `description:`| use a "Use when …" formula generated from existing content |

**Frontmatter ordering** in the migrated output (top-down):

1. `name:`
2. `description:`
3. `version:`
4. `allowed-tools:`
5. Any preserved legacy key, kept as a YAML comment for one release cycle:
   ```yaml
   # tools: [...]   # legacy; renamed to allowed-tools
   ```

The comment lets downstream consumers find the rename and migrate their own
references. After one release cycle (or a follow-up `migrate --finalize`),
the comments can be pruned manually.

---

## Body-level rewrites during migration

Some structural changes require body-level edits, not just relocation:

- **Routing table creation.** When Shape B fires (embedded handlers), the
  migration plan inserts a routing table near the top of SKILL.md. Each row
  points at the new `references/subcommands/<name>.md` file. Columns:
  `Subcommand | Type | Read/Write | One-line workflow`.
- **Rule loading map insertion.** Always insert a `## Rule loading map`
  section near the bottom of SKILL.md after extractions. Map every new
  reference file to its loading subcommand or condition.
- **Heading rename `## Pitfalls` → `## Red Flags`.** Per the destination
  table. Content is preserved; only the heading changes.
- **Announce callout insertion.** If absent, insert immediately after the
  opening summary. The user gates this just like any other diff hunk.

Body-level rewrites are visible in the diff. The user gates each one.

---

## What `migrate` never assumes

- Never assumes a section is redundant because the orchestrator essentials
  cover it. If in doubt, route to `references/_legacy/`.
- Never assumes the new archetype matches the old. Re-detect after
  migration.
- Never auto-installs missing optional composers.
- Never edits content during extraction. Extraction is a relocate; rewrites
  happen in distinct `replace-section` edits.
- Never silently merges divergent copies (Shape D conflict). Ask the user
  which copy is authoritative.

---

## Recommended post-migration workflow

After `migrate` succeeds:

1. The user inspects the diff and the post-migration audit grade.
2. If grade < B, run `modernize` to address residual `partial` patterns
   (Red Flags below threshold, missing self-test, etc.).
3. After one release cycle, the user may prune the legacy frontmatter
   comments and any `references/_legacy/` files that turned out to be
   genuinely redundant.

`migrate --with-modernize` runs steps 1-2 in one pass. v1 prefers separate
runs so the user reviews structural changes before pattern additions.
