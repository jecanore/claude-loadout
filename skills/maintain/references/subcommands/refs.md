# Subcommand: `refs`

Migration stale-pattern fixing across documentation, comments, and tests.

## refs vs links — disambiguation

These are often confused. Read this before invoking either.

| | `refs` | `links` |
|---|---|---|
| **Operates on** | Symbol/identifier references in any file (functions, types, modules, library names, commands, conceptual terms) | Markdown URL/path links specifically (`[text](url)`, `[text](./path.md)`, bare URLs) |
| **Triggered by** | "Old API name still appears in docs", "rename swept code but missed comments", "stale references after migration" | "Broken links in docs", "404s in README", "internal link points to deleted file" |
| **Inputs** | `old_patterns` + `new_context` (or discovery mode — see below) | A scope (defaults to all markdown) |
| **Spec** | this file | [links.md](./links.md) |

If you are scanning for **broken markdown links**, stop reading and route to `links`. If you are scanning for **outdated identifiers/terms**, stay here.

## Two invocation modes

`refs` accepts two distinct calling shapes. The first input row determines the mode.

### Mode A — Targeted sweep (caller supplies the rename)

The caller already knows what was renamed/removed and what replaced it. Provide `old_patterns` + `new_context` and the skill runs the full 5-step workflow against that scope. **This is the canonical mode** — most precise, most predictable.

### Mode B — Discovery (caller wants candidates surfaced)

The caller suspects stale references exist but does not have a concrete pattern list yet. The skill auto-derives candidates from three sources, presents them with file:line evidence, and waits for the user to confirm a subset before entering the EXECUTE workflow. **Discovery never edits autonomously** — it produces a proposal.

Mode selection rules:

- `old_patterns` provided → Mode A. Any discovery-mode flag is ignored. (`old_patterns` always wins.)
- `old_patterns` absent, `--discover` flag present OR no positional inputs at all → Mode B.
- Both absent and the user explicitly named a migration in prose → derive `old_patterns` from prose (Mode A); consult `rules/discovery-patterns.md`.

The 5-step workflow (DISCOVER → CATEGORIZE → PLAN → EXECUTE → VERIFY) runs identically once a pattern set is committed; only the source of the pattern set differs.

## TodoWrite Items

### Mode A (targeted sweep)

```
- [ ] Confirm old_patterns + new_context are present
- [ ] Step 1: DISCOVER — grep across scope
- [ ] Step 2: CATEGORIZE — assign priority tiers (1–6)
- [ ] Step 3: PLAN — present per-tier change plan; WAIT for user approval
- [ ] Step 4: EXECUTE — Tier 1 → Tier 6 in order
- [ ] Step 5: VERIFY — modified-file sweep + repo-wide sweep + lint + build (if applicable)
```

### Mode B (discovery)

```
- [ ] Step 0a: Enumerate auto-derived candidates from three sources (rules/discovery-patterns.md §"Auto-Derived Discovery Sources")
- [ ] Step 0b: Score, deduplicate, and batch (≤ 25 candidates per proposal screen)
- [ ] Step 0c: Present candidate proposal with file:line evidence; WAIT for user confirmation
- [ ] Step 0d: User selects subset → becomes old_patterns + new_context
- [ ] Continue at Step 1 of Mode A workflow
```

## Input

| Parameter | Required | Mode | Description | Example |
|---|---|---|---|---|
| `old_patterns` | Yes (Mode A) | A | Grep-compatible patterns | `mock, src/lib/mock, all data.*mocked` |
| `new_context` | Yes (Mode A) | A | Brief description of replacement | `PostgreSQL via src/lib/database/` |
| `--discover` | No | B | Enable discovery mode (implicit if no positional inputs) | `--discover` |
| `--since <ref>` | No | B | Git ref to scan history from (default: `HEAD~30` or last tag) | `--since=v0.4.0` |
| `scope` | No | A, B | Directory scope (default: repo root) | `src/`, `docs/` |
| `exclude` | No | A, B | Skipped dirs (default: `node_modules,.next,dist,.git`) | `vendor/,build/` |

If user provides description but not explicit patterns in Mode A, derive from description; consult `rules/discovery-patterns.md` for common migrations.

## Step 0 (Mode B only): DISCOVERY

Load `rules/discovery-patterns.md` §"Auto-Derived Discovery Sources". Run the three sources in parallel:

1. **Git rename/delete log** — `git log -p --diff-filter=DR --since=<since-ref>` to surface symbols deleted or renamed in recent history.
2. **AI-context-file claims** — grep `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `README.md` for symbol-shaped tokens (function/type/module names) and verify each still exists in source via Grep over `scope`.
3. **Repo watchlist** — if `.claude/stale-watchlist.md` exists, include its forbidden patterns as candidates (already structured per `rules/stale-watchlist.md`).

For each candidate, attach a confidence score (HIGH / MEDIUM / LOW) and at least one file:line of supporting evidence. Deduplicate across the three sources.

### Empty-state handling

If all three sources return zero candidates:

> No stale-reference candidates surfaced from the last `<since-ref>` of git history, the AI-context files, or `.claude/stale-watchlist.md`. Either the repo has no recent renames, or migrations were already swept. Re-run with `--since=<earlier-ref>`, supply `old_patterns` directly, or stop here.

Stop. Do not invent candidates.

### Batching

If candidates exceed 25, present the top batch (highest-confidence + Tier 1 file overlap) on the first proposal screen; offer "show next batch" rather than dumping all. Never present more than ~25 entries in a single `AskUserQuestion`-style prompt — the user cannot triage that many at once.

### Proposal format

```
DISCOVERY PROPOSAL — <N> candidates (showing 1–25)

[1] HIGH   `getUserById`        evidence: CLAUDE.md:14, README.md:88
                                git: deleted in 3a4b5c6 ("rename to fetchUser")
[2] HIGH   `src/lib/mock/`      evidence: docs/architecture.md:42
                                git: directory removed in 9d8e7f0
[3] MEDIUM `endpoint`           evidence: CLAUDE.md:21
                                source: term still legitimately used elsewhere
[4] LOW    `legacy-flag`        evidence: README.md:130
                                source: only one mention; may be intentional
...

Select candidates to include in the sweep:
  - "all" / "all HIGH" / numbered list (e.g. "1,2,4")
  - "skip N" to drop a candidate as a known false positive
  - "stop" to abort
For each accepted candidate, supply (or confirm a derived) new_context.
```

After confirmation, the selected subset becomes `old_patterns` and `new_context`. Mode B then enters Step 1 of the standard workflow. The CATEGORIZE/PLAN/EXECUTE/VERIFY phases are unchanged — discovery only feeds the inputs.

## Step 1: DISCOVER

Run `Grep` with each `old_patterns` across `scope`. Record file path, line number, match context, occurrence count per file.

Output: discovery report with totals and tier assignments.

## Step 2: CATEGORIZE

Load `rules/priority-tiers.md`. Sort into tiers:

| Tier | Impact | File Types | Action |
|------|--------|------------|--------|
| 1 | CRITICAL | CLAUDE.md, .cursorrules, .github/copilot-instructions.md | Edit immediately |
| 2 | HIGH | README.md, CONTRIBUTING.md, docs/*.md | Edit — onboarding |
| 3 | HIGH | .planning/, ARCHITECTURE.md, STRUCTURE.md | Edit — architecture |
| 4 | MEDIUM | Source comments (*.ts, *.tsx, *.js) | Edit comments only, not logic |
| 5 | LOW | Test files | Flag for separate fix |
| 6 | LOW | Historical/archived docs | Add disclaimer header only |

The 6-tier system applies identically in Mode A and Mode B — discovery feeds the tier system, it does not bypass it.

## Step 3: PLAN

Load `rules/update-strategies.md`. Per tier (1→6), generate: file path, line numbers, current text, replacement.

**Present full plan to user for approval before execution.**

## Step 4: EXECUTE

Process one tier at a time, highest priority first.

Per tier:
1. Apply edits via Edit tool.
2. After tier completes, Grep the tier's files to verify stale patterns removed.
3. If an edit fails (non-unique `old_string`), expand context and retry.

If `/technical-writing` is available, apply its composition rules when rewriting doc sections.

## Step 5: VERIFY

Load `rules/verification.md` (§B):
1. **Modified-file sweep** — all `old_patterns` across modified files → expect zero matches.
2. **Repo-wide sweep** — all `old_patterns` across entire repo → document any remaining (excluded scope, archived files).
3. **Lint check** — confirm no broken imports.
4. **Build check** — if source comments or config were modified.
5. Output final refs report.

## Quality Gate

PASS:
- Modified-file sweep returns zero matches for `old_patterns`.
- Lint passes.
- (If applicable) build passes.

FAIL:
- Tier 1–3 files still contain stale patterns.

Recovery: re-run execute on failed tiers; or surface as known-remaining and let user decide.

For Mode B specifically: a rejected candidate (the user marks it as a legitimate external-API name or intentional reference) must NOT enter EXECUTE. The proposal screen is the gate. If the user rejects every candidate, the run completes with status `no-action` — this is success, not failure.

## Red flags

- **Never run `refs` while `git status` shows merge or rebase in progress.** Stale-pattern fixes mid-merge corrupt the resolution. The pre-gate aborts; do not work around it.
- **Never enter EXECUTE in Mode B without an explicit candidate-selection confirmation.** Discovery surfaces proposals; the user converts them into `old_patterns`. Auto-promoting HIGH-confidence candidates is forbidden — even "obvious" deletions can be legitimate references (e.g., a documented public API kept for backward compatibility).
- **Never silently degrade Mode A to Mode B.** If the caller passes `old_patterns` and the grep returns zero hits, that's a Mode A empty result — report it and stop. Do not pivot to discovery.
- **Never auto-derive a candidate from a single LOW-confidence signal and present it as HIGH.** Confidence scoring is part of the discovery contract; inflating it to push a sweep through is a discipline failure.
