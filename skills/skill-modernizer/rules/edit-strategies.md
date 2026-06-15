# Edit Strategies — Per-pattern recipes for adding modernization edits

**Loaded by:** `modernize`, `migrate`

**Version:** 1.0

---

## Purpose

For each of the 10 patterns in `pattern-catalog.md`, this file specifies how
to convert a `partial` or `absent` finding into a concrete `ProposedEdit`
(see `references/state-schema.md`). Each recipe answers four questions:

1. **What kind of edit?** (`add-section`, `replace-section`,
   `extract-to-reference`, `add-frontmatter-key`, `split-monolith`).
2. **Where does it land?** Anchor in SKILL.md or a new file path.
3. **How is the content generated?** Step-by-step recipe.
4. **What goes wrong?** Common pitfalls.

Edit kinds at a glance:

| Kind | Mutates | Creates | Use when |
|---|---|---|---|
| `add-section`           | yes | no  | section is missing |
| `replace-section`       | yes | no  | section exists but wrong shape |
| `extract-to-reference`  | yes | yes | inline content too long for SKILL.md |
| `add-frontmatter-key`   | yes | no  | required frontmatter key missing |
| `split-monolith`        | yes | yes | structural reshape (migration) |

---

## Anchor regex conventions

Recipes use anchors to locate insertion points robustly. Anchors are forgiving
regexes — they tolerate variant section ordering. All anchor regexes are
multiline (`(?m)`) and case-insensitive (`(?i)`) unless noted.

Common anchors:

```regex
FRONTMATTER_END    = (?ms)\A---\s*\n.*?\n---\s*\n
HEADING_LEVEL_2    = (?im)^##\s+(.+?)\s*$
ROUTING_TABLE      = (?im)^##\s+routing\s+table\b
RED_FLAGS_HEADING  = (?im)^##\s+red\s+flags\b
RATIONALIZATION    = (?im)^##\s+rationalization\b
PROVIDES_HEADING   = (?im)^##\s+(provides|consumes|composition|integration)\b
END_OF_FILE        = (?ms)\Z
```

When two anchors could match, prefer the **earliest** match unless the recipe
specifies otherwise.

---

## Pattern 1 — Decision graph

**Edit kind:** `add-section`

**Target location:** After the routing table if present; otherwise after the
"What this skill does" / opening summary; otherwise after frontmatter.

**Diff anchors:**

```regex
PRIMARY = (?im)^##\s+routing\s+table\b
FALLBACK_1 = (?im)^##\s+what\s+this\s+skill\s+does\b
FALLBACK_2 = FRONTMATTER_END
```

Insert immediately **after** the matched section (i.e., after the next
heading-2 boundary or end-of-file, whichever comes first).

**Recipe:**

1. Read the skill's subcommands and pre-gate from SKILL.md.
2. Generate a `dot` (graphviz) graph with nodes:
   - `start` (`shape=doublecircle`).
   - `parse` if subcommands exist.
   - `preflight` (always; `shape=diamond`).
   - One node per subcommand or workflow phase.
   - `done` (`shape=doublecircle`).
3. Edges follow the documented control flow. Decision branches use
   `shape=diamond` nodes.
4. Wrap the graph in a fenced block tagged `dot`.
5. Add a one-sentence preamble: "Decision graph (read top-down)."

**Common pitfalls:**

- Inserting a graph that does not reference the skill's actual subcommands.
  The auditor's detection rule requires that link.
- Using `mermaid` syntax inside a `dot` fence. Match the fence tag to the
  body language.
- Generating a graph that contains only one linear chain. If the workflow is
  truly linear, switch to `add-frontmatter-key` for the `archetype:` key
  (set to `single-purpose-flexible` or `reference-only`) so the rubric
  treats the missing graph as `n/a`.

---

## Pattern 2 — Red Flags table

**Edit kind:** `add-section` or `replace-section`

**Target location:** After Rationalization Defense if it exists; otherwise
after pre-gate / preflight section; otherwise immediately before
`## Provides` / `## Consumes` / end-of-file.

**Diff anchors:**

```regex
EXISTING        = RED_FLAGS_HEADING
LIKE_NAMES      = (?im)^##\s+(pitfalls|don[''-]?t|warnings|gotchas)\b
INSERT_BEFORE_1 = (?im)^##\s+rationalization\b
INSERT_BEFORE_2 = PROVIDES_HEADING
```

If `EXISTING` matches, the edit kind is `replace-section` and the existing
content is preserved (merged into the new list, deduplicated). If
`LIKE_NAMES` matches, **do not** insert a parallel section — first migrate
the existing content into a `## Red Flags` heading, then extend.

**Recipe:**

1. List rationalization-prone failure modes specific to this skill:
   - Re-read the skill's pre-gate, gates, and any user-approval points.
   - For each gate, write one Red Flag of the form
     "<doing X> without <required pre-gate / approval>".
2. Add at least one Red Flag for each mutation entry point.
3. Add a generic catch-all for "marking a phase complete without verifying
   its exit criterion".
4. Total must be **≥ 4 items**. Five or more is recommended.
5. Format as a bulleted list under `## Red Flags`.
6. Open with the line: "These thoughts mean STOP. You are rationalizing."

**Common pitfalls:**

- Inserting generic "don't do bad things" entries. Each Red Flag must name a
  specific reasoning failure the skill is prone to.
- Creating a parallel `## Red Flags` when `## Pitfalls` (or similar) already
  exists. Migrate first; never have two such sections.
- Adding fewer than 4 items — the auditor scores `partial` below threshold.

---

## Pattern 3 — Rationalization Defense table

**Edit kind:** `add-section` or `replace-section`

**Target location:** After Red Flags. Pair them: Red Flags lists the
thoughts; Rationalization Defense pairs each thought with its rebuttal.

**Diff anchors:**

```regex
EXISTING        = RATIONALIZATION
INSERT_AFTER    = RED_FLAGS_HEADING
INSERT_BEFORE   = PROVIDES_HEADING
```

If `EXISTING` matches, switch to `replace-section`; preserve existing rows
and extend. If `INSERT_AFTER` matches, insert immediately after the Red Flags
section's terminating boundary.

**Recipe:**

1. Build a two-column table with headers `Excuse | Reality`.
2. Source rows from:
   - Each Red Flag — convert "STOP if X" into the matching excuse.
   - Common skill-authoring anti-patterns from the catalog.
   - Skill-specific shortcuts the author can think of (the wizard prompts
     for these on `create`; here the recipe seeds them from Red Flags).
3. **At least 5 rows.**
4. Each `Reality` column states the rebuttal directly — no hedging.

**Common pitfalls:**

- Single-column lists. The auditor requires the two-column structure.
- Generic philosophical rebuttals. Reality column must point to a concrete
  consequence ("backup retention bounds disk; skipping is never the right
  answer") not abstract advice ("be careful").
- Headers like `Thought | Truth` are accepted by the auditor (synonyms) but
  prefer `Excuse | Reality` for consistency across skills.

---

## Pattern 4 — TodoWrite-atomic checklists

**Edit kind:** `add-section`

**Target location:** After the per-subcommand sections (or, for single-
purpose skills, after the workflow section).

**Diff anchors:**

```regex
INSERT_AFTER_1 = (?im)^##\s+routing\s+table\b
INSERT_AFTER_2 = (?im)^##\s+workflow\b
INSERT_BEFORE  = PROVIDES_HEADING
```

**Recipe:**

1. For each subcommand (or for the single workflow), emit a numbered list:
   ```
   ### <subcommand> checklist
   1. Pre-gate.
   2. <phase 1>.
   3. <phase 2>.
   ...
   ```
2. Each step is a single atomic action — one verb, one object.
3. Open the section with: "For each subcommand, create a TodoWrite item per
   phase **before** starting work. Mark `in_progress` on entry, `completed`
   immediately on exit. Atomic. Never batch."

**Common pitfalls:**

- Multi-action steps ("Run tests and update docs"). Split.
- Omitting the opening guidance. The auditor's detection rule looks for the
  TodoWrite mention in proximity.
- Procedures with fewer than 3 steps. The pattern requires 3+.

---

## Pattern 5 — Announce-before-act

**Edit kind:** `add-section` (or insert at top of SKILL.md as a callout)

**Target location:** Near the top of SKILL.md, after the opening summary.
The instruction must be early enough that the reader sees it before any
workflow detail.

**Diff anchors:**

```regex
INSERT_AFTER_1 = (?im)^#\s+\S.*$        // SKILL title
INSERT_AFTER_2 = (?im)^>\s*\*\*?announce // existing announce callout
```

If an existing announce callout matches, do nothing (already present).

**Recipe:**

1. Insert a blockquote line immediately after the opening summary:
   ```
   > **Announce at start (every invocation):** "Using <skill-name> to
   > {phase|subcommand} {target}."
   ```
2. Replace `<skill-name>` with the skill's frontmatter `name:`.
3. If the skill has no concept of `target`, drop that token.

**Common pitfalls:**

- Burying the instruction inside a deep section. The auditor's detection
  rule is forgiving but the practical effect depends on the reader seeing it
  early.
- Using imperative voice without the example phrasing. The example anchors
  the convention.

---

## Pattern 6 — Rigid / Flexible labeling

**Edit kind:** `add-frontmatter-key` (preferred) or annotation in routing
table (acceptable for orchestrators).

**Target location:**

- Frontmatter for single-purpose skills: add `type: rigid` or `type: flexible`.
- Routing table for orchestrators: ensure each row's `Type` column is
  populated.

**Diff anchors:**

```regex
FRONTMATTER  = FRONTMATTER_END
ROUTING_ROW  = (?m)^\|\s*`?(\S+?)`?\s*\|
```

**Recipe:**

1. Inspect each workflow.
2. If it has explicit gates / approvals → label `rigid`.
3. If it is judgment-driven → label `flexible`.
4. For orchestrators, edit the routing table to populate the `Type` column on
   every row.
5. For single-purpose, add `type:` key to frontmatter.

**Common pitfalls:**

- Labeling everything `rigid` reflexively. Judgment-heavy workflows are
  legitimately `flexible`; mislabeling distorts the rubric.
- Mixing labels at the SKILL.md body level when the routing table is the
  authoritative location for orchestrators.

---

## Pattern 7 — `allowed-tools` frontmatter

**Edit kind:** `add-frontmatter-key`

**Target location:** Inside the YAML frontmatter block.

**Diff anchors:**

```regex
FRONTMATTER  = FRONTMATTER_END
```

**Recipe:**

1. Scan SKILL.md and reference files for explicit tool mentions
   (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `AskUserQuestion`,
   `Task`, etc.).
2. Build the minimal set the skill actually invokes.
3. Add to frontmatter as a YAML list under `allowed-tools:`.
4. Preserve YAML key order: `name`, `description`, `version`, then
   `allowed-tools`.

**Common pitfalls:**

- Padding the list with tools the skill doesn't use. The pattern's intent is
  capability surface, not aspiration.
- Forgetting to include `Bash` when the skill calls scripts in `scripts/`.
- Renaming variant: `allowedTools` (camelCase) is accepted by the auditor;
  prefer `allowed-tools` (kebab-case) for consistency.

---

## Pattern 8 — `references/` progressive disclosure

**Edit kind:** `extract-to-reference` (per long inline section) +
`add-section` (rule loading map in SKILL.md).

This recipe is more involved because it creates files.

**Target location:**

- New files: `references/<topic>.md` — one per extracted section.
- Loading map: a table near the bottom of SKILL.md (before
  `## Provides` / quick reference).

**Diff anchors:**

```regex
LONG_SECTION  = (?ms)^##\s+(.+?)\s*$\n([\s\S]{1500,}?)(?=^##\s|\Z)
LOADING_MAP   = (?im)^##\s+rule\s+loading\s+map\b
```

A "long section" is a heading-2 whose body exceeds ~1,500 characters and is
not part of the orchestrator essentials (Red Flags, Rationalization,
Decision graph, routing table, TodoWrite, Provides/Consumes — these stay
inline).

**Recipe:**

1. For each `LONG_SECTION` match that is not orchestrator-essential:
   1. Generate a slug from the heading: lowercase, hyphenate, strip
      punctuation.
   2. Create `references/<slug>.md` with:
      - A header line: `# <Original heading>`.
      - A `**Loaded by:** <subcommand>` line.
      - The full original body content. **Do not edit content during
        extraction.** Only relocate.
   3. In SKILL.md, replace the section body with a single line:
      `See \`references/<slug>.md\` for details.`
2. After all extractions, ensure SKILL.md has a `## Rule loading map`
   section. If absent, `add-section` it. Map every `references/` file to its
   loading subcommand. Use the table format from the audit template.
3. Each subcommand reference must declare its loads explicitly at the top.

**Common pitfalls:**

- Extracting orchestrator essentials. The whole point is that SKILL.md stays
  scannable but still contains the orchestration logic. Red Flags,
  Rationalization, Decision graph, routing table, TodoWrite checklists, and
  Provides/Consumes stay inline. Extraction targets long-form prose,
  archetype templates, scenario lists, etc.
- Editing content during extraction. Extraction is a relocate, not a
  rewrite. Any rewrite happens in a separate `replace-section` edit on the
  new file, after the user gates the relocation.
- Forgetting to add the rule loading map. Without it, the auditor cannot
  detect this pattern.
- Extracting into `references/_legacy/` when the section is current. The
  `_legacy/` namespace is reserved for `migrate`'s preserve-but-disclaim
  flow.

---

## Pattern 9 — RED / GREEN / REFACTOR self-test

**Edit kind:** `extract-to-reference` (creates `references/skill-self-test.md`)
+ `add-section` (self-test pointer in SKILL.md).

This recipe **always asks the user** for input. Self-test scenarios are
specific to the skill's contract; the auditor cannot fabricate them.

**Target location:**

- New file: `references/skill-self-test.md`.
- Pointer: a short `## Self-test pointer` section in SKILL.md, near the
  bottom.

**Diff anchors:**

```regex
EXISTING_FILE = references/(skill-self-test|self-test|scenarios|acceptance-tests)\.md
POINTER_SLOT  = (?im)^##\s+quick\s+reference\b
```

If `EXISTING_FILE` matches a non-empty file, switch to `replace-section` on
that file: preserve all existing scenarios, extend to satisfy the
"≥ 5 scenarios" threshold.

**Recipe:**

1. Use `AskUserQuestion` to elicit **3-5 scenarios** specific to this skill.
   Prompt format:
   ```
   The self-test file lists scenarios this skill must handle. Each scenario
   has Setup / Invocation / Expected behavior / Failure modes.

   Provide 3-5 scenarios for <skill-name>. Examples for inspiration:
   - happy-path: <skill> on a typical valid input.
   - edge: <skill> on the most unusual valid input.
   - failure: <skill> on an invalid input it must reject.
   - composition: <skill> when its optional dependency is absent.
   - regression: a bug you have already fixed and want to lock down.
   ```
2. Combine the user's scenarios with auditor-generated baseline scenarios:
   - Pre-gate failure (path missing, frontmatter malformed).
   - Mutation aborted mid-run (if the skill has mutating workflows).
   - Composition with a missing optional dependency.
3. Write `references/skill-self-test.md` with the structured-fields layout:
   ```
   ## Scenario 1 — <name>

   **Setup:** ...
   **Invocation:** ...
   **Expected behavior:** ...
   **Failure modes:** ...
   ```
4. Add a `## Self-test pointer` section to SKILL.md:
   ```
   Pressure scenarios for this skill itself live in
   `references/skill-self-test.md`. Run `pressure-test <path-to-this-skill>`
   to verify all scenarios pass.
   ```

**Common pitfalls:**

- Auto-generating scenarios without asking the user. The auditor will detect
  a present file but the scenarios will be generic and useless under
  pressure-test. Always ask.
- Fewer than 5 scenarios after combining user + baseline. Re-prompt the user
  for additional scenarios rather than padding with filler.
- Skipping the SKILL.md pointer. The pointer keeps the self-test discoverable
  to readers who don't `ls references/`.

---

## Pattern 10 — Provides / Consumes composability

**Edit kind:** `add-section`

**Target location:** Near the bottom of SKILL.md, before `## Quick
reference` or `## Self-test pointer`.

**Diff anchors:**

```regex
EXISTING       = PROVIDES_HEADING
INSERT_BEFORE  = (?im)^##\s+(quick\s+reference|self-test\s+pointer)\b
INSERT_AT_END  = END_OF_FILE
```

**Recipe:**

1. Build the **Provides** list from:
   - Public output schemas (e.g., `audit --json` schema).
   - Append-only event logs the skill writes (history JSONL, backup index).
   - Stable conventions other skills can rely on.
2. Build the **Consumes** list from:
   - Optional composer skills detected in the dependency-detection step.
   - Any external tool / file / convention the skill requires.
3. Mark each Consumes entry as required or optional.
4. Format as two parallel sub-sections:
   ```
   ## Provides

   - capability: ...
   - schema: ...

   ## Consumes

   - <skill-name> (optional): ...
   ```

**Common pitfalls:**

- Single-section variants ("Composition" with mixed entries). Acceptable to
  the auditor but harder for ecosystem consumers to scan. Prefer two
  sections.
- Including non-public commitments in Provides. Only items other skills can
  rely on belong.
- Padding Consumes with tools (`Read`, `Write`). Tools are frontmatter,
  not Consumes. Consumes is for *other skills*.

---

## When two recipes would touch the same anchor

The catalog order in `pattern-catalog.md` is the tiebreaker — earlier
patterns insert first. The diff renderer merges adjacent insertions into a
single hunk so the output stays readable.

If the merge would produce ambiguous output (two new headings sharing a
line), the second recipe's insertion is shifted down by one section
boundary; this is logged in the modernize report under "edit ordering".

---

## When a recipe needs information the auditor cannot infer

Use `AskUserQuestion`. Never fabricate. The recipes for Self-test (#9) and
Decision graph (#1, when subcommand intent is unclear) routinely need input.
The Rationalization Defense (#3) recipe may also ask for skill-specific
shortcuts the author wants to pre-empt.

The user's answers become part of the `ProposedEdit`'s `after` content and
are visible in the diff before the gate.
