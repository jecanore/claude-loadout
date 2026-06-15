# Archetypes — file-tree templates for new skills

**Loaded by:** `create`

**Version:** 1.0

---

## What an archetype is

An **archetype** is a shape of skill. It determines:

1. **Which patterns are required vs optional** for that skill (cross-referenced in `rules/scoring-rubric.md`).
2. **The scaffold layout** the `create` wizard writes (this file).
3. **The detection defaults** auditors use when frontmatter omits an explicit `archetype:` key.

There are exactly four archetypes. New shapes are not minted ad-hoc; they are added via `refresh` after evidence accumulates.

| Archetype | When to use |
|---|---|
| `orchestrator-with-subcommands` | Three or more subcommands, each with its own workflow |
| `single-purpose-rigid` | One workflow, gates required, must run exactly |
| `single-purpose-flexible` | One workflow, judgment-driven, no hard gates |
| `reference-only` | Pure knowledge skill, no actions to take |

A skill that does not fit one of these is a sign the design is unfocused. The wizard does not provide a fifth option; refactor the idea instead.

---

## `orchestrator-with-subcommands`

### When to choose

Choose this archetype when the skill has three or more distinct verbs (`audit`, `modernize`, `score`, etc.) and each verb has its own workflow, loaded references, and report format. The orchestrator's `SKILL.md` is the routing surface; deep content lives under `references/subcommands/<verb>.md` and shared rules live under `rules/`.

If you only have one or two verbs, prefer `single-purpose-rigid` or `single-purpose-flexible`. Promoting a small skill to orchestrator is a common rationalization trap; it adds load without adding clarity.

### File tree

```
<skill-name>/
├── SKILL.md
├── references/
│   ├── state-schema.md
│   ├── subcommands/
│   │   └── <first-verb>.md
│   └── skill-self-test.md
└── rules/
    ├── pattern-or-domain-rule-1.md
    └── json-schema.md
```

The wizard writes one stub per subcommand the user lists. Cross-cutting domain rules live in `rules/`; per-subcommand workflows live in `references/subcommands/`.

### SKILL.md skeleton

````markdown
---
name: <skill-name>
description: Use when <one-line-trigger>. Triggers on phrases like "<phrase-1>", "<phrase-2>", "<phrase-3>". Provides <one-line-capability>.
version: 0.1.0
allowed-tools:
  - <tool-1>
  - <tool-2>
---

# <skill-name>

<one-paragraph description of what this skill does>

> **Announce at start (every invocation):** "Using <skill-name> to {subcommand} {target}."

---

## Routing table — subcommands

| Subcommand | Type | Read/Write | One-line workflow |
|---|---|---|---|
| `<verb-1> <args>` | <rigid|flexible> | <read-only|mutating> | <PHASE → PHASE → PHASE> |
| `<verb-2> <args>` | <rigid|flexible> | <read-only|mutating> | <PHASE → PHASE → PHASE> |

---

## Decision graph

```dot
digraph <skill_name>_flow {
  rankdir=TB;
  start [label="user invokes /<skill-name>[ subcommand]" shape=doublecircle];
  parse [label="parse subcommand"];
  preflight [label="pre-gate" shape=diamond];
  fail [label="STOP — surface" shape=box style=dashed];
  done [label="done" shape=doublecircle];

  start -> parse -> preflight;
  preflight -> fail [label="fail"];
  preflight -> done [label="pass"];
  // [scaffold placeholder — replace before shipping with full subcommand routing]
}
```

---

## Pre-gate (every invocation)

[scaffold placeholder — replace before shipping with the conditions every subcommand must verify before acting]

---

## Red Flags

These thoughts mean STOP. You are rationalizing.

- [scaffold placeholder — replace before shipping with 4+ rationalization-prone failures specific to this skill]

---

## Rationalization Defense

| Excuse | Reality |
|---|---|
| [scaffold placeholder — replace before shipping] | [scaffold placeholder — replace before shipping] |

---

## TodoWrite atomic checklists

For each subcommand, create a TodoWrite item per phase before starting work. Mark `in_progress` when entering a phase, `completed` immediately on exit.

### <verb-1> checklist

1. [scaffold placeholder — replace before shipping]

---

## Provides

- [scaffold placeholder — replace before shipping]

## Consumes

- [scaffold placeholder — replace before shipping]

---

## Self-test pointer

Pressure scenarios for this skill live in `references/skill-self-test.md`. Run pressure-test against this skill's directory to verify all scenarios pass.
````

### `references/` stubs

- `references/state-schema.md` — shared in-memory state shape across subcommands.
- `references/subcommands/<verb>.md` — one per subcommand the wizard collected. Each mirrors the audit.md template (Loads on entry, Type, Workflow, Steps, Report format, Red Flags, What X never does).
- `references/skill-self-test.md` — five RED/GREEN/REFACTOR scenarios as `[scaffold placeholder]` rows.

### `rules/` stubs

- `rules/json-schema.md` — present only when any subcommand emits `--json`; the wizard offers to scaffold it.
- `rules/<domain-rule>.md` — one stub per cross-cutting concern the wizard surfaces (when applicable).

### Sample subcommand reference stub

````markdown
# `<verb>` — <one-line description>

**Loads on entry:**
- `rules/<rule-1>.md`
- `references/state-schema.md`

**Type:** <rigid|flexible>, <read-only|mutating>

---

## Workflow

```
<PHASE-1> → <PHASE-2> → <PHASE-3>
```

---

## Steps

1. **Pre-gate.** [scaffold placeholder — replace before shipping]
2. [scaffold placeholder — replace before shipping]

---

## Report format (default)

```
[scaffold placeholder — replace before shipping]
```

---

## What `<verb>` never does

- [scaffold placeholder — replace before shipping]
````

### Required patterns checklist

This archetype must satisfy patterns 1, 2, 3, 4, 5, 6, 7, 9 as **required** and 8, 10 as **recommended**. See the orchestrator column of the weight table in `rules/scoring-rubric.md`.

| Pattern | Status |
|---|---|
| 1. Decision graph | required |
| 2. Red Flags | required |
| 3. Rationalization Defense | required |
| 4. TodoWrite-atomic checklists | required |
| 5. Announce-before-act | required |
| 6. Rigid/Flexible labeling | required |
| 7. `allowed-tools` frontmatter | required |
| 8. `references/` progressive disclosure | recommended |
| 9. Self-test | required |
| 10. Provides/Consumes | recommended |

### What this archetype is NOT for

Not for skills with one or two verbs — the routing scaffolding is overhead without payoff. Not for pure knowledge skills (those go to `reference-only`). When in doubt, start smaller; promoting a single-purpose skill to an orchestrator later is cheap, demoting an orchestrator is expensive.

---

## `single-purpose-rigid`

### When to choose

Choose this when the skill has one workflow that must run exactly — gates, approvals, no shortcuts. Examples: a deployment skill that requires explicit confirmation before pushing; a security audit skill that refuses to skip steps. The user invokes the skill and expects identical execution every time.

If the workflow tolerates judgment calls or context-driven shortcuts, use `single-purpose-flexible` instead. Mislabeling a flexible skill as rigid produces a frustrated user; mislabeling a rigid skill as flexible produces silent failures.

### File tree

```
<skill-name>/
├── SKILL.md
└── references/
    └── skill-self-test.md
```

Optional: `references/<extra>.md` for any deep content the SKILL.md offloads via progressive disclosure. The wizard offers to scaffold an additional reference file when the user signals they have content to offload.

### SKILL.md skeleton

````markdown
---
name: <skill-name>
description: Use when <one-line-trigger>. Triggers on phrases like "<phrase-1>", "<phrase-2>", "<phrase-3>".
version: 0.1.0
allowed-tools:
  - <tool-1>
  - <tool-2>
---

# <skill-name>

**Type:** rigid

<one-paragraph description>

> **Announce at start:** "Using <skill-name> to <action> <target>."

---

## Workflow

```
<PHASE-1> → <PHASE-2> → <PHASE-3> → <PHASE-4>
```

---

## Decision graph

```dot
digraph <skill_name>_flow {
  rankdir=TB;
  start [label="invoke" shape=doublecircle];
  preflight [label="pre-gate" shape=diamond];
  gate [label="user gate" shape=diamond];
  fail [label="STOP" shape=box style=dashed];
  done [label="done" shape=doublecircle];

  start -> preflight;
  preflight -> fail [label="fail"];
  preflight -> gate [label="pass"];
  gate -> fail [label="declined"];
  gate -> done [label="approved"];
  // [scaffold placeholder — replace before shipping with full flow]
}
```

---

## Pre-gate

[scaffold placeholder — replace before shipping with the verifications every invocation runs]

---

## Steps

1. [scaffold placeholder — replace before shipping]
2. [scaffold placeholder — replace before shipping]

---

## Red Flags

These thoughts mean STOP. You are rationalizing.

- [scaffold placeholder — replace before shipping with 4+ rationalization-prone failures]

---

## Rationalization Defense

| Excuse | Reality |
|---|---|
| [scaffold placeholder — replace before shipping] | [scaffold placeholder — replace before shipping] |

---

## TodoWrite checklist

1. [scaffold placeholder — replace before shipping]

---

## Provides

- [scaffold placeholder — replace before shipping]

## Consumes

- [scaffold placeholder — replace before shipping]

---

## Self-test pointer

Pressure scenarios live in `references/skill-self-test.md`.
````

### `references/` stubs

- `references/skill-self-test.md` — **mandatory** for this archetype. Five RED/GREEN/REFACTOR scenarios as `[scaffold placeholder]` rows; each scenario has Setup / Invocation / Expected / Failure-modes fields.
- `references/<extra>.md` — optional progressive-disclosure file when the wizard signals offload content.

### `rules/` stubs

None by default. If the wizard surfaces a cross-cutting domain rule (e.g., `rules/<domain>.md`), it's added under `references/` rather than `rules/` for this archetype — `rules/` is reserved for orchestrators where multiple subcommands share rules.

### Required patterns checklist

| Pattern | Status |
|---|---|
| 1. Decision graph | required |
| 2. Red Flags | required |
| 3. Rationalization Defense | required |
| 4. TodoWrite-atomic checklists | required |
| 5. Announce-before-act | required |
| 6. Rigid/Flexible labeling | required |
| 7. `allowed-tools` frontmatter | required |
| 8. `references/` progressive disclosure | optional |
| 9. Self-test | required |
| 10. Provides/Consumes | recommended |

See the rigid column of the weight table in `rules/scoring-rubric.md`.

### What this archetype is NOT for

Not for judgment-driven workflows — gates are required, and a flexible skill labeled rigid will frustrate users who want to adapt. Not for multi-verb skills; promote to `orchestrator-with-subcommands` once a second verb earns its own workflow.

---

## `single-purpose-flexible`

### When to choose

Choose this when the skill has one workflow but execution adapts to context — no hard gates, no required step ordering. Examples: a code review skill that picks which checks to run based on the diff; a brainstorming skill that adapts depth to the user's energy. The user invokes the skill and expects intelligent execution, not identical execution.

If the workflow has even one mandatory gate (user approval before mutation, security check before install), use `single-purpose-rigid` instead. The rigid/flexible distinction is binary; "mostly flexible with one gate" is rigid.

### File tree

```
<skill-name>/
├── SKILL.md
└── references/
    └── <one-or-more-deep-content>.md
```

Self-test is **optional** for this archetype because flexible skills don't have a fixed expected behavior to test against. The wizard offers to scaffold a self-test stub anyway; users can decline.

### SKILL.md skeleton

````markdown
---
name: <skill-name>
description: Use when <one-line-trigger>. Triggers on phrases like "<phrase-1>", "<phrase-2>", "<phrase-3>".
version: 0.1.0
allowed-tools:
  - <tool-1>
  - <tool-2>
---

# <skill-name>

**Type:** flexible

<one-paragraph description; emphasize the judgment dimensions this skill operates on>

> **Announce at start:** "Using <skill-name> to <action> <target>."

---

## Approach

<2-4 paragraphs describing how the skill thinks about its task. Flexible skills earn their flexibility by being explicit about the heuristics they apply.>

---

## Decision graph (optional but recommended)

```dot
digraph <skill_name>_flow {
  rankdir=TB;
  start [label="invoke" shape=doublecircle];
  assess [label="assess context" shape=diamond];
  done [label="done" shape=doublecircle];

  start -> assess -> done;
  // [scaffold placeholder — replace before shipping with the major branches in your judgment]
}
```

---

## Red Flags

These thoughts mean STOP. You are rationalizing.

- [scaffold placeholder — replace before shipping with 4+ rationalization-prone failures]

---

## Rationalization Defense

| Excuse | Reality |
|---|---|
| [scaffold placeholder — replace before shipping] | [scaffold placeholder — replace before shipping] |

---

## Provides

- [scaffold placeholder — replace before shipping]

## Consumes

- [scaffold placeholder — replace before shipping]
````

### `references/` stubs

- `references/<deep-content>.md` — one or more files for content that doesn't belong in SKILL.md. The wizard prompts for a list.
- `references/skill-self-test.md` — optional; offered but not mandatory.

### `rules/` stubs

None. Flexible single-purpose skills don't share rules across subcommands (there are no subcommands).

### Required patterns checklist

| Pattern | Status |
|---|---|
| 1. Decision graph | recommended |
| 2. Red Flags | required |
| 3. Rationalization Defense | recommended |
| 4. TodoWrite-atomic checklists | optional |
| 5. Announce-before-act | recommended |
| 6. Rigid/Flexible labeling | required |
| 7. `allowed-tools` frontmatter | required |
| 8. `references/` progressive disclosure | optional |
| 9. Self-test | optional |
| 10. Provides/Consumes | recommended |

See the flexible column of the weight table in `rules/scoring-rubric.md`. The rubric is more lenient here because flexibility is, itself, a property worth preserving — over-instrumenting a flexible skill kills the thing.

### What this archetype is NOT for

Not for skills with mandatory gates (those are rigid, even if other steps are flexible). Not for skills that are mostly informational with no actions (those are `reference-only`). Not for multi-verb skills.

---

## `reference-only`

### When to choose

Choose this when the skill is pure knowledge — patterns, conventions, examples — and takes no actions. Examples: a writing-style guide; a list of accessibility patterns; a glossary of domain terms. The skill is loaded by the harness when a relevant phrase appears, and the model's response cites or applies the knowledge directly.

If the skill takes any action (writing files, running commands, asking the user a question that affects state), it is not `reference-only`. Promote to `single-purpose-flexible` at minimum.

### File tree

```
<skill-name>/
└── SKILL.md
```

Optional: `examples/` directory for sample artifacts the SKILL.md references. The wizard prompts for whether examples are needed.

### SKILL.md skeleton

````markdown
---
name: <skill-name>
description: Use when <one-line-trigger>. Triggers on phrases like "<phrase-1>", "<phrase-2>", "<phrase-3>".
version: 0.1.0
---

# <skill-name>

<one-paragraph description of the knowledge this skill provides>

> **Announce at start:** "Applying <skill-name> guidance."

---

## <topic-1>

<content>

---

## <topic-2>

<content>

---

## Red Flags

These thoughts mean STOP. You are rationalizing.

- [scaffold placeholder — replace before shipping with 4+ rationalization-prone failures specific to applying this knowledge]

---

## Provides

- [scaffold placeholder — replace before shipping]

## Consumes

- [scaffold placeholder — replace before shipping; often empty for reference-only skills]
````

Note: `allowed-tools` is omitted from the frontmatter for this archetype unless the skill needs Read/Glob to load examples on demand. The rubric does not penalize the omission.

### `references/` stubs

None by default. If the wizard signals examples, scaffold an `examples/` directory with one placeholder file.

### `rules/` stubs

None. Reference-only skills don't have rules; they *are* the rule.

### Required patterns checklist

| Pattern | Status |
|---|---|
| 1. Decision graph | n/a |
| 2. Red Flags | required |
| 3. Rationalization Defense | optional |
| 4. TodoWrite-atomic checklists | n/a |
| 5. Announce-before-act | optional |
| 6. Rigid/Flexible labeling | n/a |
| 7. `allowed-tools` frontmatter | optional |
| 8. `references/` progressive disclosure | n/a |
| 9. Self-test | n/a |
| 10. Provides/Consumes | recommended |

See the reference-only column of the weight table in `rules/scoring-rubric.md`. Most patterns are `n/a`; the rubric does not penalize their absence. Red Flags is still required because even knowledge skills have rationalization risks (e.g., "I'll skip citing this because it's obvious").

### What this archetype is NOT for

Not for skills that take any action, ask any question, or write any file. Not for skills with subcommands (those are orchestrators by definition). If you find yourself wanting a TodoWrite checklist or a decision graph, you're not building a reference-only skill — promote.

---

## How `create` consumes this file

When the wizard finishes, it reads the matching archetype section above and writes one file at a time using the embedded skeletons as templates. Substitution rules:

- `<skill-name>` → the wizard's `name` answer.
- `<one-line-trigger>` and trigger phrases → the wizard's `description` answer.
- `<tool-1>`, `<tool-2>` → the wizard's `allowed-tools` multi-select.
- `<verb-1>`, `<verb-2>` → the wizard's subcommand list (orchestrator only).
- `[scaffold placeholder — replace before shipping]` markers are written verbatim so the user knows exactly what to customize.

The wizard never silently fills placeholders with reasonable-looking content. The marker is the signal; filler hides the gap.
