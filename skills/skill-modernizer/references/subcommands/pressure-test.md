# `pressure-test <path>` — stress-test a skill against scenario catalog

**Loads on entry:**
- `rules/scenario-catalog.md`
- `references/state-schema.md`
- `rules/parallel-dispatch.md` (only when independent scenarios fan out)
- `references/skill-self-test.md` (only when target is `skill-modernizer` itself)
- `rules/json-schema.md` (only with `--json`)

**Type:** rigid, read-only (writes report only)

---

## Workflow

```
DETECT-DEPS → SCENARIOS → REPORT
```

Never mutates the target skill. Writes one report file under the skill-modernizer config directory and (optionally) appends one history entry.

---

## Steps

1. **Pre-gate.**
   - Resolve `<path>` to absolute. STOP if it doesn't exist.
   - Verify a `SKILL.md` exists at the root. STOP otherwise.
   - Cache paths are allowed (read-only); emit a banner noting the target is plugin-managed and that any subsequent `modernize` would need a copy first.

2. **Detect optional composers.**

   Detect `superpowers:writing-skills` with this glob logic:

   ```
   glob "$CLAUDE_HOME/plugins/cache/**/writing-skills/SKILL.md"
   glob "$CLAUDE_HOME/skills/writing-skills/SKILL.md"
   either match → installed=true
   ```

   `$CLAUDE_HOME` is the user's Claude config directory (commonly the dotfile directory at `<your Claude config directory>`). When neither glob matches, `installed=false`.

   - **If installed:** parse the writing-skills `SKILL.md` defensively by section heading (regex against `^##\s+...`), never by line number. The TDD Iron Law and the RED/GREEN/REFACTOR sequence are extracted from named sections; if the parse cannot find them, stop with this exact message and do not silently fall back:

     ```
     writing-skills structure has changed; pressure-test composition broken
     — please update skill-modernizer
     ```

   - **If absent:** offer install with three options:

     ```
     This subcommand works best with `superpowers:writing-skills` installed.
     Without it, pressure-test runs in reduced-rigor mode (skips Iron Law).

     Install now?
       command: npx skills add obra/superpowers
       [y]es / [n]o / [r]educed-rigor mode
     ```

     - On `y`: optionally invoke `Remote_Skill_Security_Check` if installed; then run `npx skills add`. Re-detect; on success, proceed in full-rigor mode.
     - On `n`: abort the subcommand. Do not produce a partial report.
     - On `r`: set `state.invocation.flags.reducedRigor = true`. Reduced-rigor mode skips scenario `tdd-iron-law` and stamps a banner on the report.

3. **Detect target archetype.**
   - Same logic as `audit` (frontmatter `archetype:` key, then structural inference, fallback to `unknown`).
   - Used to filter scenarios via each scenario's `Applies to` list.

4. **Select scenarios.**
   - Default: every scenario in `rules/scenario-catalog.md` whose `Applies to` includes the detected archetype and whose `Skip if` condition is not satisfied.
   - With `--scenarios <name1,name2>`: run only the named scenarios (still subject to `Applies to` filtering — names that don't apply emit `SKIP` with reason `archetype-mismatch`).

5. **Plan parallelism.**
   - Scenarios that read disjoint files and produce no shared mutations are independent and may fan out one Explore subagent each. See `rules/parallel-dispatch.md` for the dispatch envelope.
   - Scenarios that depend on a prior scenario's parsed result (e.g., `decision-graph-parses` after `frontmatter-validity`) run sequentially.

6. **Execute scenarios.**
   - For each scenario: run setup, invoke per scenario `Invocation`, compare against `Expected behavior`.
   - Emit one of: `PASS` / `FAIL` / `SKIP`.
   - On `FAIL`, capture the specific `Failure mode` matched and a 1-2 sentence note.
   - On `SKIP`, capture the reason (`archetype-mismatch`, `composer-absent`, `reduced-rigor`, `not-applicable`, `dependency-skipped`).

7. **Compute overall.**
   - **PASS overall** iff every RED scenario emitted `PASS` AND no RED scenario was skipped except for reasons listed in `rules/scenario-catalog.md` as legitimate skip conditions for that scenario.
   - Any RED `FAIL` → overall `FAIL`.
   - Any RED `SKIP` whose skip reason is not legitimate → overall `FAIL` (skipped ≠ failed; skipped means the scenario didn't run, and an unjustified skip is treated as a failure to verify).
   - GREEN scenarios are advisory: `FAIL` or `SKIP` produce notes but do not change the overall verdict.

8. **Write report file.**

   Path:

   ```
   <config>/.skill-modernizer/reports/pressure-test-<skill>-<ISO-date>.md
   ```

   Where `<config>` is the user's Claude config directory and `<ISO-date>` is the report timestamp. The report file lives in **the skill-modernizer config directory, never inside the target skill**.

9. **Append history entry** (optional; `pressure-test` events use action `pressure-test`).

---

## Report format (default, human-readable)

```
Pressure test: <name> (v<semver>) — archetype: <archetype>
Path:    <absolute-path>
Date:    <ISO>
Mode:    full-rigor | reduced-rigor (no writing-skills)
Report:  <report-file-path>

[ Reduced-rigor banner — only when Mode=reduced-rigor ]
─────────────────────────────────────────────────────────────
This run skipped the TDD Iron Law because superpowers:writing-skills
is not installed. Install with `npx skills add obra/superpowers`
and re-run for full-rigor verification.

Scenario results
─────────────────────────────────────────────────────────────
 Color  Scenario                          Result   Notes
 RED    frontmatter-validity              PASS     —
 RED    decision-graph-parses             PASS     —
 RED    trigger-phrase-coverage           PASS     —
 RED    reference-loading-map-consistent  FAIL     2 orphan refs: rules/foo.md, references/bar.md
 RED    pre-gate-execution                PASS     —
 RED    mutating-without-gate             PASS     —
 RED    tdd-iron-law                      SKIP     reduced-rigor
 GREEN  reduced-rigor-banner              PASS     —
 RED    self-reference                    n/a      not an orchestrator
 RED    plugin-cache-safety               PASS     —

Overall: FAIL
Reason:  1 RED FAIL (reference-loading-map-consistent)

Suggested next step
───────────────────
Run `audit <path>` for fix hints, then `modernize <path>` to apply.
```

---

## Report format (with `--json`)

Schema in `rules/json-schema.md`. Top level:

```json
{
  "version": "1.0",
  "skill": "<name>",
  "path": "<absolute-path>",
  "archetype": "<archetype>",
  "mode": "full-rigor",
  "scenarios": [
    {
      "name": "frontmatter-validity",
      "color": "RED",
      "result": "PASS",
      "notes": ""
    }
  ],
  "overall": "PASS",
  "reduced_rigor_banner": false,
  "report_file": "<absolute-path>"
}
```

`mode` is one of `full-rigor` or `reduced-rigor`. `reduced_rigor_banner` is `true` whenever `mode == reduced-rigor`.

---

## With `--scenarios <list>`

Comma-separated scenario names (`--scenarios frontmatter-validity,decision-graph-parses`). Only those scenarios run; everything else emits `SKIP` with reason `not-selected` and is not counted in the overall verdict.

Useful for:
- Fast iteration on a specific failing scenario during `modernize`.
- CI gates that only check structural patterns, not Iron Law.

---

## Parallel dispatch

When two or more scenarios are independent (disjoint reads, no shared parse results), pressure-test fans out one Explore subagent per scenario. The dispatch envelope, batch sizing, and aggregation rules are in `rules/parallel-dispatch.md`.

A failed dispatch (subagent crash, timeout) aggregates as scenario `SKIP` with reason `dispatch-failed`. A scenario whose result is `dispatch-failed` is treated like an unjustified skip for the overall verdict (i.e., RED scenarios that fail to dispatch fail the overall verdict).

---

## Self-targeting

When `<path>` resolves to the `skill-modernizer` directory itself, pressure-test additionally loads `references/skill-self-test.md` and runs the self-reference test (scenario `self-reference`). Self-test is required to PASS for `refresh` to subsequently mutate the catalog.

---

## What pressure-test never does

- Never edits the target skill.
- Never edits the target skill's referenced files.
- Never installs composers without explicit user approval (`y` in the prompt).
- Never claims overall PASS while any RED scenario was skipped without a legitimate skip reason. Skipped ≠ failed; skipped means the scenario didn't run, and the verdict must reflect that.
- Never writes the report inside the target skill directory.
- Never falls back silently if `writing-skills` parsing breaks — fails loudly with the canonical message so composition drift is visible.
- Never mutates `rules/pattern-catalog.md` or `rules/scenario-catalog.md`. Those files are owned by `refresh`.
