# skill-modernizer

> Audit, modernize, create, and refresh agent skills. A meta-skill for keeping your skill library high-quality, portable, and current.

`skill-modernizer` codifies a portable **Skill Quality Template** — 10 patterns that consistently appear in well-built skills — and ships subcommands that apply, audit, and evolve that template.

## Why this exists

Skills proliferate. Many are written once and never revisited. Best practices evolve. Without an opinionated audit tool, your skill library drifts: some skills have decision graphs and Red Flags, others are monolithic prose; some have self-tests, others crash on edge cases nobody noticed.

`skill-modernizer` solves this by making quality measurable, mutations gated, and the template itself updatable.

## Install

```
npx skills add <user>/skill-modernizer
```

(Replace `<user>` with the maintainer's account. The skill registers in your local skills directory and becomes available in your Claude harness immediately.)

## What you get

- **`audit <path>`** — pattern-checklist + letter grade for any skill.
- **`score <path>`** — one-line grade.
- **`modernize <path>`** — bring a skill up to standard with diff preview + user gate.
- **`migrate <path>`** — convert a legacy monolithic SKILL.md into a split, progressive-disclosure layout.
- **`create <name>`** — wizard-driven scaffold of a new skill with every pattern pre-wired.
- **`pressure-test <path>`** — run the skill against acceptance scenarios.
- **`refresh`** — research current best practices and update the pattern catalog.
- **`audit-all [scope]`** — bulk audit a directory of skills using parallel agents.
- **`prune-backups`** — manage retention.

## Usage

### Audit a single skill

```
/skill-modernizer audit ./my-skill/
```

Returns:

- Pattern checklist (10 rows, ✓/~/✗/—)
- Per-pattern letter
- Overall letter grade (A-F)
- Suggested fixes with file:line pointers

### Score quickly

```
/skill-modernizer score ./my-skill/
```

One-line grade output. Suitable for CI gates.

### Modernize

```
/skill-modernizer modernize ./my-skill/
```

Walks: backup → audit → propose edits → diff preview → user gate → apply → re-audit → version bump → mark verified.

### Create a new skill

```
/skill-modernizer create my-new-skill
```

Walks: archetype selection → 6-8 wizard prompts → full scaffold → automatic pressure-test of the scaffold.

### Refresh the pattern catalog

```
/skill-modernizer refresh
```

Dispatches parallel research agents against canonical sources, presents a diff against the current pattern catalog, gates on user approval, applies, and self-audits.

Recommended cadence: **monthly is reasonable; quarterly is fine**.

### Bulk audit

```
/skill-modernizer audit-all
```

Default scope is your skills directory. Dispatches up to 10 parallel agents, each handling ~5 skills. Configure with `--parallelism N` or `--batch-size N`.

```
/skill-modernizer audit-all --parallelism 5 ./team-skills/
```

## CI integration

`audit --json`, `score --json`, and `audit-all --json` emit machine-readable output suitable for gates.

### GitHub Actions example

A sample workflow ships at `examples/.github/workflows/skill-audit.yml`:

```yaml
name: Skill audit

on:
  pull_request:
    paths:
      - 'skills/**'

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run skill audit
        run: |
          npx skill-modernizer audit-all --json ./skills > audit.json
      - name: Check for grade regressions
        run: |
          jq -e '.skills[] | select(.overall_grade == "F")' audit.json && exit 1 || exit 0
```

This fails the PR when any skill scores `F`.

### Pre-commit hook

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit
set -euo pipefail

changed_skills=$(git diff --cached --name-only --diff-filter=ACM | grep '/SKILL.md$' | xargs -n1 dirname | sort -u)

for skill in $changed_skills; do
  current_grade=$(npx skill-modernizer score --json "$skill" | jq -r '.overall_grade')
  prior_grade=$(git show HEAD:"$skill"/SKILL.md 2>/dev/null \
    | npx skill-modernizer score --json /dev/stdin | jq -r '.overall_grade' || echo "F")

  if [[ "$current_grade" > "$prior_grade" ]]; then
    echo "Grade regression in $skill: $prior_grade → $current_grade"
    exit 1
  fi
done
```

(Compares grades alphabetically — `F > A`, so a regression is when the current grade is alphabetically greater than the prior.)

## The 10 patterns

The skill audits against:

1. **Decision graph** — visual control flow.
2. **Red Flags** — specific rationalization-prone failure modes.
3. **Rationalization Defense** — Excuse / Reality table.
4. **TodoWrite-atomic checklists** — discrete, trackable steps.
5. **Announce-before-act** — narrate intent before tool calls.
6. **Rigid / Flexible labeling** — workflow disposition declared.
7. **`allowed-tools` frontmatter** — capability surface explicit.
8. **`references/` progressive disclosure** — load-on-demand content.
9. **Self-test scenarios** — RED/GREEN/REFACTOR acceptance suite.
10. **Provides / Consumes** — composability with other skills.

Full detection rules and rationale: `rules/pattern-catalog.md`.

## Archetypes

`create` supports 4 archetypes; the rubric weights patterns differently per archetype.

| Archetype | When to choose |
|---|---|
| `orchestrator-with-subcommands` | 3+ subcommands needed |
| `single-purpose-rigid` | One workflow, gates required |
| `single-purpose-flexible` | Judgment-driven, no gates |
| `reference-only` | Pure knowledge skill, no actions |

Full templates: `rules/archetypes.md`.

## Backups

Every mutation creates a snapshot at `<your-claude-config>/.backups/skill-modernizer/<skill>-<date>/` with an append-only index. Retention: **3 backups per skill** + **30-day TTL**.

Backups are placed **outside** the skills directory so the loader doesn't register them as skills.

Manual cleanup: `/skill-modernizer prune-backups [--all | --skill <name> | --older-than <days>]`.

## Composition

`skill-modernizer` composes with optional dependencies:

- **`superpowers:writing-skills`** — `pressure-test` invokes its TDD Iron Law if installed; otherwise runs in reduced-rigor mode.
- **`Remote_Skill_Security_Check`** — security pre-check before installing remote skills via `npx skills add`.
- **`find-skills`** — discoverability companion.

If a composer is missing, `skill-modernizer` offers to install it (with the user's explicit approval) before continuing. Decline to fall back to reduced-rigor mode.

## Contributing

1. Run `/skill-modernizer audit ./skill-modernizer` against this skill before opening a PR.
2. Self-audit must report 10/10 ✓ and grade A.
3. Add scenarios to `references/skill-self-test.md` for any new behavior.
4. Run the 18-step verification suite documented in the contribution guide.

## License

MIT.
