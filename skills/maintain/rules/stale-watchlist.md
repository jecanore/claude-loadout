# Stale Pattern Watchlist — Rule File

Consumed by `sync` Step 3.5 (WATCHLIST SCAN). Opt-in per repo.

## Contract

A repo opts into watchlist scanning by creating `.claude/stale-watchlist.md` in its root. The file is a plain-markdown inventory of forbidden strings and patterns that should NEVER appear in live documentation.

If the file does not exist, Step 3.5 is a no-op. The skill must not warn about the absence — the watchlist is optional.

## File Format

The repo's `.claude/stale-watchlist.md` uses these top-level sections (parse by `## ` heading, case-insensitive):

- `## Forbidden literal strings` — plain strings to grep verbatim
- `## Forbidden regex patterns` — ripgrep-compatible regexes
- `## Route-group invariants` (optional) — domain-specific prose rules; treat as literal-string matches unless the bullet makes clear it's a regex

Each bullet follows this shape:
```
- `<pattern>` — <reason it's forbidden, including when it was added / under what circumstance it expires>
```

The pattern MUST be wrapped in backticks so it survives markdown escaping. The reason is free-form prose.

## Scanning

For each pattern:
1. `ripgrep --glob '<doc targets>' -nH -e '<pattern>'` (use `--fixed-strings` for the literal-strings section, full regex for the regex section).
2. Exclude files inside paths named in the "Exclusions" list of `rules/doc-targets.md`.
3. Exclude any match whose line falls between `<!-- gitnexus:start -->` / `<!-- gitnexus:end -->` markers (auto-regenerated).

Each hit produces a structured entry:

```
{
  file: '<path>',
  line: <n>,
  matched_text: '<line contents>',
  rule_pattern: '<pattern>',
  rule_reason: '<reason>',
  watchlist_section: 'literal | regex | invariant',
}
```

## Reporting

Append all hits to the existing GAP report produced by Step 3, tagged with source `WATCHLIST`. Present them at the top of the report — these are known-regression signals and deserve the highest attention.

Example output row:

```
WATCHLIST  README.md:591  '225.5 hours' (reason: frozen metric; cut 2026-04-18)
```

## Resolution

**Do not auto-apply fixes.** Present each hit as a proposed edit alongside the standard GAP resolutions; require user approval per the existing `sync` Step 4 flow.

If a hit is expected (the pattern truly belongs in that file — e.g. the watchlist itself citing its own examples), the user's options are:
1. Remove the string from the doc and keep the rule.
2. Remove the rule from the watchlist (if the reason expired).
3. Narrow the rule (e.g. exclude a specific file via a regex anchor).

## Anti-patterns

- Do not scan source code (`*.ts`, `*.tsx`, etc.). The watchlist is strictly for documentation drift. Code refactors are handled by the `refs` subcommand.
- Do not treat watchlist hits as blocking errors. They are warnings that require human judgment.
- Do not silently add new entries to the repo's watchlist. The watchlist is curated by the repo owner; the skill reads it, never writes it.

## Interaction with existing rules

- Runs after Step 3 (ANALYZE) so its output joins the same GAP report.
- Does NOT replace Step 4 (stale-reference validation in `full`) — that step checks concrete claims against the codebase; the watchlist checks for specific known-bad strings regardless of whether the surrounding claim is accurate.
- Complements `refs` subcommand: `refs` fixes patterns across a migration; watchlist catches single known regressions between migrations.
