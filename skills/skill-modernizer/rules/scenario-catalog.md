# Scenario Catalog — pressure-test scenarios

**Loaded by:** `pressure-test`

**Version:** 1.0

---

## What scenarios are

A **scenario** is one kind of test pressure-test can run on any target skill. Each scenario is portable: it does not name a specific skill, only the structural property it verifies. The catalog is intentionally generic so `pressure-test` works across the whole skill ecosystem without per-target customization.

Scenarios are organized into two colors:

- **RED scenarios** are must-pass. A `FAIL` or unjustified `SKIP` on any RED scenario fails the overall verdict.
- **GREEN scenarios** are advisory. They surface useful information (e.g., reduced-rigor banner present) but their result does not change the overall verdict.

## How RED / GREEN / REFACTOR maps onto skill testing

When `superpowers:writing-skills` is installed, pressure-test borrows its TDD Iron Law as one scenario (`tdd-iron-law`) and runs the RED/GREEN/REFACTOR sequence on the target skill's own test discipline.

For all other scenarios, the mapping is:

| TDD phase  | Pressure-test interpretation |
|---|---|
| RED        | Scenario asserts the skill **fails** under a specific bad input (e.g., pre-gate refuses an invalid path). The scenario `PASS`es when the failure is observed. |
| GREEN      | Scenario asserts the skill **succeeds** under a specific good input (e.g., frontmatter parses). The scenario `PASS`es when success is observed. |
| REFACTOR   | Scenario asserts the skill remains **structurally sound** after a property-style perturbation (e.g., a reference file rename forces the loading map to be updated; the skill must still parse). |

A scenario's color (RED/GREEN) is independent of its TDD phase. Color is about whether the scenario is must-pass; TDD phase is about what kind of behavior it checks.

---

## Scenario fields

Each scenario specifies:

- **Name** — kebab-case identifier used in `--scenarios <list>`.
- **Color** — `RED` (blocks PASS overall) or `GREEN` (advisory).
- **Applies to** — archetype list. `*` means all archetypes.
- **Intent** — one-sentence purpose.
- **Setup** — what state the scenario assumes.
- **Invocation** — what the scenario does.
- **Expected behavior** — observable outcome that yields `PASS`.
- **Failure modes** — observable outcomes that yield `FAIL`.
- **Skip if** — conditions that yield `SKIP` (with reason).

---

## Scenarios

### 1. frontmatter-validity

- **Color:** RED
- **Applies to:** `*`
- **Intent:** Confirm SKILL.md frontmatter parses as YAML and contains required keys.
- **Setup:** Target SKILL.md exists.
- **Invocation:** Read the leading `---`-delimited block; parse as YAML; check for keys `name`, `description`, `version`, `allowed-tools` (the last is conditional — see notes).
- **Expected behavior:** YAML parses without errors; `name`, `description`, `version` are present and non-empty; `allowed-tools` is present unless archetype is `reference-only`.
- **Failure modes:**
  - YAML parse error.
  - Missing `name` / `description` / `version`.
  - `allowed-tools` missing on a non-`reference-only` skill.
  - `version` is not a valid semver.
- **Skip if:** Never. Frontmatter is mandatory.

---

### 2. decision-graph-parses

- **Color:** RED
- **Applies to:** `orchestrator-with-subcommands`, `single-purpose-rigid`
- **Intent:** Confirm the SKILL.md decision graph fenced code block is syntactically well-formed.
- **Setup:** Pattern #1 (decision graph) is `present` per audit.
- **Invocation:** Extract the fenced block tagged `dot`, `mermaid`, or `graphviz`. Apply a regex-level syntactic sanity check (matched braces for `digraph`, balanced `[...]` attribute lists, no unterminated quoted labels). This is **not** a full graphviz/mermaid parse — it's a regex sanity pass that catches authoring typos.
- **Expected behavior:** Block is well-formed at the regex level.
- **Failure modes:**
  - Unbalanced braces.
  - Unterminated quoted label.
  - Empty fenced block.
  - Wrong language tag for content (e.g., `dot` content inside ```` ```mermaid ````).
- **Skip if:** Pattern #1 is `n/a` for this archetype (e.g., `single-purpose-flexible`, `reference-only`) — emit `SKIP` with reason `not-applicable`. (Legitimate skip; does not block PASS.)

---

### 3. trigger-phrase-coverage

- **Color:** RED
- **Applies to:** `*` except `reference-only`
- **Intent:** Confirm the trigger phrases the skill claims in its description are reflected in the description's actual text.
- **Setup:** SKILL.md frontmatter `description` exists.
- **Invocation:** Extract claimed trigger phrases from any `Triggers on:` / `Use when:` clauses in the description. For each, perform a textual match against the description and any "Triggers" section in SKILL.md.
- **Expected behavior:** Every claimed trigger phrase is textually present in the description or a Triggers section.
- **Failure modes:**
  - A phrase listed in a `Triggers on` clause does not appear in the description body.
  - The skill claims to handle a phrase pattern with no surface in the discoverable text.
- **Skip if:** Description has no claimed triggers (legitimate for very narrow skills) — emit `SKIP` with reason `no-triggers-claimed`. (Legitimate skip.)

> Note: this is a textual match, not a real harness check. A real harness would dispatch the skill from a simulated user prompt; that's out of scope for pressure-test, which is read-only.

---

### 4. reference-loading-map-consistent

- **Color:** RED
- **Applies to:** `orchestrator-with-subcommands`, `single-purpose-rigid`, `single-purpose-flexible`
- **Intent:** Every file under `references/` and `rules/` is referenced by at least one place in SKILL.md or a subcommand reference. No orphans.
- **Setup:** Target has `references/` or `rules/` directory.
- **Invocation:** Enumerate files under `references/**` and `rules/**`. For each, grep across SKILL.md and `references/subcommands/*.md` for a textual reference (path or relative form). Build the set of unreferenced files.
- **Expected behavior:** The orphan set is empty.
- **Failure modes:**
  - One or more files exist on disk but are not loaded by any subcommand or SKILL.md section.
- **Skip if:** Target has no `references/` and no `rules/` directory — emit `SKIP` with reason `not-applicable`. (Legitimate skip.)

---

### 5. pre-gate-execution

- **Color:** RED
- **Applies to:** `single-purpose-rigid`, `orchestrator-with-subcommands`
- **Intent:** Skills with rigid pre-gates produce a clear STOP message when gate fails.
- **Setup:** SKILL.md declares a Pre-gate (or equivalent) section.
- **Invocation:** Simulate calling the skill with an input that the documented pre-gate should reject (e.g., for path-taking skills, a non-existent path; for skills that take a name, an empty name). Read the SKILL.md text governing this case.
- **Expected behavior:** The SKILL.md text states an explicit STOP, refusal, or surface-and-abort behavior — not a silent retry, not a guess.
- **Failure modes:**
  - SKILL.md describes the failure mode but says "retry" or "guess" instead of STOP.
  - SKILL.md describes the failure mode but the surfaced message is implicit (e.g., "the skill should figure out what to do").
  - SKILL.md does not describe the failure mode at all.
- **Skip if:** Skill declares no pre-gate (legitimate for `single-purpose-flexible`) — emit `SKIP` with reason `no-pre-gate`. (Legitimate skip.)

---

### 6. mutating-without-gate

- **Color:** RED
- **Applies to:** any archetype with at least one mutating subcommand or workflow
- **Intent:** Mutating subcommands always require an explicit user gate before any file change. Verify the SKILL.md / subcommand references contain explicit gate language and not "apply directly".
- **Setup:** Target has at least one mutating subcommand or workflow.
- **Invocation:** For each mutating subcommand reference, search for explicit gate language: `**GATE**`, `await explicit approval`, `present diff to user`, `user gate`, or equivalent. Then search for anti-patterns: `apply edits directly`, `skip the diff`, `no preview needed`.
- **Expected behavior:** Every mutating subcommand has explicit gate language **and** no anti-pattern phrasing.
- **Failure modes:**
  - A mutating subcommand reference contains no gate language.
  - A mutating subcommand reference contains anti-pattern phrasing.
- **Skip if:** Target has no mutating subcommands (e.g., a pure read-only audit skill) — emit `SKIP` with reason `no-mutations`. (Legitimate skip.)

---

### 7. tdd-iron-law

- **Color:** RED
- **Applies to:** `single-purpose-rigid`, `orchestrator-with-subcommands`
- **Intent:** When `superpowers:writing-skills` is composed, run its TDD Iron Law and RED/GREEN/REFACTOR sequence on the target skill.
- **Setup:** `superpowers:writing-skills` is installed; full-rigor mode is active.
- **Invocation:** Defer to the writing-skills SKILL.md sections for Iron Law and RED/GREEN/REFACTOR. Apply each step against the target skill's self-test file (`references/skill-self-test.md` or equivalent), checking that the skill is testable in the discipline writing-skills enforces.
- **Expected behavior:** Iron Law passes; RED/GREEN/REFACTOR sequence completes without violations.
- **Failure modes:**
  - Iron Law violation reported by the composed skill.
  - RED step has no failing scenario to satisfy.
  - GREEN step has no green path verified.
  - REFACTOR step degrades the skill's structure (e.g., breaks the loading map).
- **Skip if:**
  - `writing-skills` is not installed AND user chose reduced-rigor mode → `SKIP` with reason `reduced-rigor`. **This is a legitimate skip.**
  - Target archetype is `single-purpose-flexible` or `reference-only` → `SKIP` with reason `not-applicable`. (Legitimate skip.)

---

### 8. reduced-rigor-banner

- **Color:** GREEN
- **Applies to:** `*`
- **Intent:** When pressure-test runs in reduced-rigor mode, the report includes the reduced-rigor banner so the user is reminded to install the composer.
- **Setup:** Mode is `reduced-rigor` (writing-skills absent and user chose `r` at the install prompt).
- **Invocation:** Inspect the in-memory report draft for the reduced-rigor banner string.
- **Expected behavior:** Banner is present in the rendered report and includes the install command.
- **Failure modes:**
  - Banner is absent.
  - Banner is present but missing the install command.
- **Skip if:** Mode is `full-rigor` — emit `SKIP` with reason `not-applicable`. (Legitimate skip.)

---

### 9. self-reference

- **Color:** RED
- **Applies to:** `orchestrator-with-subcommands` whose subcommands include any read-only audit/score subcommand
- **Intent:** Orchestrator skills that audit other skills must pass when pointed at themselves. Eat your own dog food.
- **Setup:** Target has a self-test reference (`references/skill-self-test.md` or equivalent) and at least one read-only audit-style subcommand.
- **Invocation:** Run the target skill's documented self-audit / self-test routine against the target itself. Compare against the self-test reference's claimed expected outcomes.
- **Expected behavior:** Self-audit grade meets the threshold the skill itself enforces (e.g., for an A/B/C/D/F rubric, the skill should grade itself A or B).
- **Failure modes:**
  - Self-audit grade falls below the skill's own enforced threshold.
  - Self-test reference describes scenarios the skill can't actually execute on itself.
- **Skip if:**
  - Target archetype is not `orchestrator-with-subcommands` — `SKIP` with reason `not-applicable`. (Legitimate skip.)
  - Target is an orchestrator without an audit-style subcommand — `SKIP` with reason `no-self-audit`. (Legitimate skip.)

---

### 10. plugin-cache-safety

- **Color:** RED
- **Applies to:** any archetype with at least one mutating subcommand
- **Intent:** Mutating subcommands refuse targets inside a plugin cache and suggest copying to a personal skills directory first.
- **Setup:** Target has at least one mutating subcommand.
- **Invocation:** Inspect SKILL.md and each mutating subcommand reference for refusal language matching paths like `*/plugins/cache/*`. Search for both the refusal and the suggested copy-first remediation.
- **Expected behavior:** SKILL.md or the relevant subcommand references contain explicit refusal-and-suggest text for plugin-cache paths.
- **Failure modes:**
  - No refusal language for plugin-cache paths.
  - Refusal exists but no copy-first suggestion.
  - Mutating subcommands describe applying edits to plugin-cache paths as acceptable.
- **Skip if:** Target has no mutating subcommands — `SKIP` with reason `no-mutations`. (Legitimate skip.)

---

## Scenario summary table

| #  | Name                              | Color | Applies to (short)                | Skip-if (short)                              |
|----|-----------------------------------|-------|-----------------------------------|----------------------------------------------|
| 1  | frontmatter-validity              | RED   | all                               | never                                        |
| 2  | decision-graph-parses             | RED   | orchestrator, rigid               | pattern n/a for archetype                    |
| 3  | trigger-phrase-coverage           | RED   | all except reference-only         | no triggers claimed                          |
| 4  | reference-loading-map-consistent  | RED   | orchestrator, rigid, flexible     | no `references/` and no `rules/`             |
| 5  | pre-gate-execution                | RED   | rigid, orchestrator               | no pre-gate declared                         |
| 6  | mutating-without-gate             | RED   | any with mutating workflow        | no mutating subcommands                      |
| 7  | tdd-iron-law                      | RED   | rigid, orchestrator               | reduced-rigor; archetype not applicable      |
| 8  | reduced-rigor-banner              | GREEN | all                               | full-rigor mode                              |
| 9  | self-reference                    | RED   | orchestrator with audit subcmd    | not orchestrator; no self-audit              |
| 10 | plugin-cache-safety               | RED   | any with mutating workflow        | no mutating subcommands                      |

---

## How to extend this catalog

`refresh` is the only subcommand authorized to mutate this file. When adding a scenario:

1. Pick the next available number.
2. Specify all fields (Name, Color, Applies to, Intent, Setup, Invocation, Expected behavior, Failure modes, Skip if).
3. Make `Applies to` archetype-aware so scenarios don't generate spurious `FAIL`s on archetypes where they don't apply.
4. Make `Skip if` explicit and finite — vague skip conditions defeat the verdict logic in pressure-test.
5. Mark the scenario `RED` only when an unjustified skip should fail the overall verdict. When in doubt, start `GREEN` and promote later.
