# Pattern Catalog — The Skill Quality Template

**Purpose:** This file defines the 10 patterns that constitute a modern, high-quality skill. Every audit, score, modernization, and create wizard reads this catalog. Detection regexes, intent, and rationale are captured here so they can evolve under `refresh` without changing core logic elsewhere.

**Loaded by:** `audit`, `score`, `modernize`, `refresh`

**Version:** 1.0

---

## How patterns are evaluated

Each pattern is independently detectable from a skill's source files. A pattern is `present` when its detection rule matches the **structural intent**, not just the literal regex. Auditors should accept variant phrasings as long as the intent is satisfied.

When in doubt, prefer a **forgiving** match (intent satisfied) over a strict one (regex match). Brittleness here cascades into bad audits everywhere else.

---

## The 10 patterns

### 1. Decision graph

**Intent:** A visual, parseable representation of the skill's control flow that a reader can scan in seconds. Forces the author to make branching logic explicit.

**Detection:**
- A fenced code block tagged `dot`, `mermaid`, or `graphviz` inside `SKILL.md`.
- The block contains at least one node with `shape=diamond` (decision) or branching arrows.
- The graph references the skill's actual subcommands or workflow phases.

**Detection regex (forgiving):** `\n```(dot|mermaid|graphviz)\n[\s\S]*?(diamond|->.*->|digraph|graph (LR|TD|TB))[\s\S]*?\n```\n`

**Common omission:** Author writes prose-only "first do X, then Y" instructions. Reader has to mentally compile control flow.

**Archetype weighting:** Required for `orchestrator-with-subcommands`, `single-purpose-rigid`. Optional for `single-purpose-flexible`. Not applicable to `reference-only`.

---

### 2. Red Flags table

**Intent:** Enumerates rationalization-prone failure modes specific to this skill. The reader sees the trap before falling into it. Distinct from generic Don't-do-this lists because each entry names a *specific reasoning failure* the skill is prone to.

**Detection:**
- A section heading matching `## Red Flags` (case-insensitive).
- The section contains a bulleted or table list with **at least 4 items**.
- Each item names a concrete action or thought that should stop the reader.

**Detection regex:** `(?im)^##\s+red\s+flags\s*$[\s\S]{50,}`

**Archetype weighting:** Required for all archetypes. Even `reference-only` skills can have rationalization risks ("I'll skip citing this because it's obvious").

---

### 3. Rationalization Defense table

**Intent:** A two-column "Excuse | Reality" table that pre-empts the most common reasoning failures. Forces the reader to confront the rationalization with its rebuttal already attached.

**Detection:**
- A section heading matching `## Rationalization` (any suffix).
- A markdown table with two columns whose headers map to `Excuse` / `Reality` (or close synonyms: `Thought`/`Reality`, `Temptation`/`Counter`, etc.).
- At least 5 rows.

**Detection regex:** `(?im)^##\s+rationalization[\s\S]*?\|\s*(excuse|thought|temptation)[\s\S]*?\|\s*(reality|counter|truth)\s*\|`

**Archetype weighting:** Required for `orchestrator-with-subcommands`, `single-purpose-rigid`. Strongly recommended for `single-purpose-flexible`. Optional for `reference-only`.

---

### 4. TodoWrite-atomic checklists

**Intent:** Multi-step procedures are broken into discrete items the executor can mark `in_progress` / `completed` one at a time. Discourages "I did them all" reasoning failures and gives the user real-time progress.

**Detection:**
- The skill contains at least one numbered or bulleted procedure with **3+ steps**.
- The procedure references TodoWrite, TaskCreate, or an equivalent task-tracking primitive.
- Steps are atomic (each step is a single action, not a paragraph).

**Detection regex (presence of guidance):** `(?im)(todowrite|taskcreate|task list|atomic\s+(checklist|step))`

**Archetype weighting:** Required for `orchestrator-with-subcommands`, `single-purpose-rigid`. Optional for `single-purpose-flexible`. Not applicable to `reference-only`.

---

### 5. Announce-before-act

**Intent:** The skill instructs its user to state, in user-facing text, what they're about to do before they do it. Improves observability and forces the author to commit to an approach before executing it.

**Detection:**
- The skill contains an explicit instruction to announce, narrate, or state intent before tool calls or file mutations.
- Example trigger phrases: "Announce:", "State in one sentence", "Before any tool call, write...", "Tell the user...".

**Detection regex:** `(?im)(announce[:\s]|state in one sentence|before (any|each) (tool|action|mutation|edit)|user-facing text)`

**Archetype weighting:** Required for `orchestrator-with-subcommands`, `single-purpose-rigid`. Recommended for `single-purpose-flexible`. Optional for `reference-only`.

---

### 6. Rigid / Flexible labeling

**Intent:** The skill explicitly states whether its workflow is rigid (follow exactly, no shortcuts) or flexible (adapt to context). Resolves ambiguity for the reader and the rubric.

**Detection:**
- The frontmatter or SKILL.md body contains an explicit `rigid` or `flexible` declaration.
- For multi-subcommand skills, each subcommand carries its own label.

**Detection regex:** `(?im)\b(rigid|flexible)\b(:|\s+(workflow|skill|subcommand))`

**Archetype weighting:** Required for all archetypes that have workflows. `reference-only` skills don't have workflows so this pattern is N/A.

---

### 7. `allowed-tools` frontmatter

**Intent:** The frontmatter declares which tools the skill needs. Lets the harness pre-load tool schemas, lets reviewers see capability surface at a glance, and locks down sprawl.

**Detection:**
- YAML frontmatter at the top of SKILL.md.
- A key named `allowed-tools` (or `allowedTools`) with a list value.
- The list is non-empty unless the skill is purely informational.

**Detection regex (frontmatter scan):** `(?m)^---\s*$[\s\S]*?^allowed[-_]?tools\s*:\s*[\s\S]*?^---\s*$`

**Archetype weighting:** Required for all archetypes that invoke tools. `reference-only` may omit (and the rubric won't penalize).

---

### 8. `references/` progressive disclosure

**Intent:** Detailed content lives in `references/` and is loaded only when a specific subcommand or scenario triggers it. SKILL.md stays scannable; deep content is one Read call away.

**Detection:**
- A `references/` directory exists alongside `SKILL.md`.
- SKILL.md contains a "rule loading map" or equivalent table mapping references to triggers.
- At least one reference is loaded conditionally, not unconditionally.

**Detection regex (loading map):** `(?im)(loaded by|loads on|triggered by)[\s\S]{0,200}references?/`

**Archetype weighting:** Recommended for `orchestrator-with-subcommands`. Optional for `single-purpose-rigid` / `single-purpose-flexible`. Not applicable for `reference-only` (the skill IS the reference).

---

### 9. RED / GREEN / REFACTOR self-test

**Intent:** The skill contains a `references/skill-self-test.md` (or equivalent) listing scenarios the skill must handle. Each scenario is structured: setup, invocation, expected behavior, failure modes. This is the skill's TDD acceptance suite.

**Detection:**
- A self-test file exists in `references/`.
- The file contains at least 5 scenarios.
- Each scenario has structured fields (Setup / Invocation / Expected / Failure modes — or close variants).

**Detection regex (file presence):** `references/(skill-self-test|self-test|scenarios|acceptance-tests)\.md`

**Archetype weighting:** Required for `single-purpose-rigid`, `orchestrator-with-subcommands`. Optional for `single-purpose-flexible`. N/A for `reference-only`.

---

### 10. Provides / Consumes composability

**Intent:** The skill explicitly lists what it provides to other skills (capabilities, conventions, output formats) and what it consumes (other skills it depends on or composes with). Makes skill ecosystem dependencies legible.

**Detection:**
- A section in SKILL.md labeled `## Provides` and/or `## Consumes` (or `## Composition`, `## Integration`).
- Lists capability strings, output schemas, or named skills.

**Detection regex:** `(?im)^##\s+(provides|consumes|composition|integration)\b`

**Archetype weighting:** Recommended for all archetypes. Lighter weight in the rubric (composability matters most for skills that compose with others).

---

## Aggregate rules

- Each pattern emits one of: `present` (✓), `partial` (~), `absent` (✗), `n/a` (—, archetype-aware).
- A `partial` finding requires a note explaining what's missing.
- The rubric (see `scoring-rubric.md`) computes the letter grade from these findings.

## When to extend this catalog

`refresh` is the only subcommand authorized to mutate this file. Manual edits are allowed but should be followed by a self-audit run to confirm the additions don't conflict with existing detection rules.

When adding a pattern:

1. Give it a number (sequential).
2. Specify intent in 1-2 sentences.
3. Provide a forgiving detection rule.
4. Specify archetype weighting.
5. Update `scoring-rubric.md` to include it in the weight table.
