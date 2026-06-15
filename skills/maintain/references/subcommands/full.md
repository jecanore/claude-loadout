# Subcommand: `full`

Audit-first orchestrated run. Default behavior of `/maintain` with no arguments.

The purpose of `full` is to determine whether maintenance artifacts are current with the repo, then apply selected fixes. Artifact existence is only one input. Never treat "file exists" as "maintenance complete."

## TodoWrite Items

Create one TodoWrite item per step before starting. Mark complete as you go — never batch.

```
Phase 1:
- [ ] 1A — Detect artifacts (parallel)
- [ ] 1B — Compute freshness range and changed files via git diff
- [ ] 1C — Audit existing artifacts for freshness/readiness (read-only)
- [ ] 1D — Present artifact freshness matrix and ranked recommendations
- [ ] 1E — Optional scaffold gate for missing artifacts; WAIT for user selection only if user wants scaffolds
- [ ] 1F — Present maintenance picklist with evidence-backed pre-checks

Phase 2 (only steps user selected):
- [ ] Step 1: Scaffold
- [ ] Step 2: GitNexus reindex
- [ ] Step 3: Sync docs (delegates to sync subcommand)
- [ ] Step 4: Validate stale references
- [ ] Step 5: Academy guides
- [ ] Step 6: Memory prune (delegates to prune subcommand)
- [ ] Step 7+: Optional new subcommands (locks/env/links/secrets/deadcode/lint-drift)

Phase 3:
- [ ] Present summary table
- [ ] Run verification §A and any new-subcommand verification sections
- [ ] Ask user about doc-only commit
- [ ] Stage doc files by explicit path; never source files; never `git add .`
```

---

## Phase 1: Detect, Audit & Present

### 1A. Detect Artifacts (parallel)

| # | Artifact | Check | If missing |
|---|---|---|---|
| 1 | Root CLAUDE.md | `CLAUDE.md` at repo root | offer scaffold |
| 2 | GitNexus Index | `.gitnexus/` exists | offer scaffold |
| 3 | Doc Spec Files | `docs/spec/` exists | offer scaffold |
| 4 | Child CLAUDE.md | `{sourceDir}/*/CLAUDE.md` exists | offer scaffold for subdirs with 3+ files |
| 5 | Academy Guides | `.academy/` + `README.md` | offer scaffold (only if 5+ source subdirs) |
| 6 | CHANGELOG.md | `CHANGELOG.md` at root | offer scaffold |
| 7 | Memory Index | MEMORY.md exists | offer scaffold |
| 8 | `.env.example` | exists at root | offer scaffold (only if env reads detected in code) |
| 9 | Lint config | `.eslintrc.*`, `ruff.toml`, `.rubocop.yml`, etc. | offer scaffold (only if framework supports linting) |

Existence detection is not a pass/fail result. Any present artifact starts as `unknown` until 1C freshness checks prove `current` or `stale`.

### 1B. Compute Freshness Range and Changed Files

```bash
# Prefer last-sync marker when present:
test -f .claude/maintain/last-sync && cat .claude/maintain/last-sync
test -f .Codex/maintain/last-sync && cat .Codex/maintain/last-sync

# On a feature branch (has upstream/main/master):
git diff main...HEAD --name-only --diff-filter=ACMR

# On main/master or no remote:
git diff --name-only HEAD~10 --diff-filter=ACMR

# If last-sync-marker exists:
git diff $(cat .claude/maintain/last-sync | jq -r .lastSyncSha)..HEAD --name-only --diff-filter=ACMR
```

Include staged and unstaged files when the working tree is dirty:

```bash
git diff --name-only --diff-filter=ACMR
git diff --staged --name-only --diff-filter=ACMR
```

Record the selected freshness range in the final report.

### 1C. Audit Existing Artifacts for Freshness/Readiness

Load `rules/freshness-audit.md` and run its read-only checks. This step happens before any scaffold prompt.

Required output statuses:

| Status | Meaning |
|---|---|
| `missing` | Artifact is absent and may be scaffolded. |
| `current` | Lightweight checks found no evidence of drift. |
| `stale` | Concrete evidence shows drift. |
| `unknown` | Artifact exists but has not been proven current. |
| `not-applicable` | Artifact does not apply to this repo. |

Do not use "already present" as a final status. Say "exists, freshness unknown" when only existence has been checked.

Minimum read-only checks before picklist:

- Compare runtime env reads against `.env.example`.
- Compare recent changed source/config files against AI docs, README, specs, and academy key files.
- Check internal markdown links in AI context and modified docs.
- Check whether GitNexus index metadata appears older than relevant source changes; if unknown, recommend reindex when source changed.
- Check lockfile/manifest drift when lockfiles and manifests exist.
- Check `MEMORY.md` size and contradiction risk when present.
- Check `CHANGELOG.md` for an `[Unreleased]` section and recent non-doc changes.

### 1D. Artifact Freshness Matrix and Ranked Recommendations

Present a table before asking for actions:

```text
| Artifact | Exists | Freshness | Evidence | Recommended action |
|---|---:|---|---|---|
| .env.example | yes | stale | SUPABASE_URL read in code but missing from example | Run env sync |
| CLAUDE.md | yes | unknown | Exists; recent source changes need doc mapping | Run sync docs |
| MEMORY.md | no | missing | No MEMORY.md found | Optional scaffold |
```

Then present action ranking:

```text
High priority:
- Env Sync — missing runtime variables in .env.example
- Sync Docs — source/config changed since last sync

Medium priority:
- GitNexus Reindex — source changed; index freshness unknown

Optional:
- Scaffold MEMORY.md — missing but not required to check freshness
```

### 1E. Scaffold Checklist — OPTIONAL GATE AFTER AUDIT

**GATE: If ANY scaffoldable artifacts from 1A are missing, present the checklist after the freshness matrix. Missing optional artifacts must not block freshness analysis.**

Present a multi-select checklist of EVERY missing artifact:

```
Optional missing artifacts detected after freshness audit. Select which to scaffold:

[ ] 1. Root CLAUDE.md           — AI context file for project conventions
[ ] 2. GitNexus Index           — Code knowledge graph (runs npx gitnexus analyze)
[ ] 3. docs/spec/               — Specification document directory
[ ] 4. Child CLAUDE.md          — Subdirectory-level AI context ({N} eligible dirs)
[ ] 5. .academy/                — Teaching guides from codebase
[ ] 6. CHANGELOG.md             — Version history tracking
[ ] 7. MEMORY.md                — Cross-session memory index
[ ] 8. .env.example             — Env-var template (env reads detected in code)
[ ] 9. Lint config              — {detected framework} lint defaults

Reply with numbers (e.g., "1,2,6") or "none" to skip all.
```

**Only show items that are actually missing.** Wait for user response before proceeding.

#### 1C.1. Post-gate control flow

- **User replies with selections** → execute scaffolds via `rules/scaffolds.md`, then re-enter 1B and 1C because scaffolds can change the freshness matrix.
- **User replies "none"** → record a warning artifact in `state.results`: `{ step: "scaffold", status: "skipped", detail: "user declined all" }`. Continue to 1F. Do not mark the whole maintenance pass failed just because optional scaffolds were declined.
- **User says "audit only"** → stop after 1D with the freshness matrix and recommendations.

### 1F. Maintenance Picklist

Present multi-select with evidence-backed pre-checks. Pre-check high-priority stale items; leave medium/optional unchecked unless the evidence is strong.

```
Which maintenance steps to run?

[x] 1. GitNexus Reindex          ← high when source files changed and index stale/unknown
[x] 2. Sync Docs                 ← high when source/config changed and docs are stale/unknown
[x] 3. Validate Stale References ← high when concrete stale path/symbol/reference evidence exists
[ ] 4. Academy Guides            ← pre-checked when changed files match Key Files in .academy/README.md
[ ] 5. Memory Prune              ← pre-checked when MEMORY.md > 200 lines
[ ] 6. Lockfile Drift            ← pre-checked when manifest changed without lockfile change (or vice versa)
[ ] 7. Env Sync                  ← high when runtime env reads are missing from .env.example
[ ] 8. Link Check                ← high when internal broken links are found; medium when docs changed
[ ] 9. Secret Scan               ← never pre-checked (opt-in defensive scan)
[ ] 10. Dead Code                ← never pre-checked (opt-in)
[ ] 11. Lint Drift               ← pre-checked when lint config changed
```

For steps that were offered in 1C but declined: show as `---` prefix with reason.

```
[x] 1. GitNexus Reindex          ← pre-checked (source files changed)
[ ] 2. Sync Docs
--- 4. Academy Guides            ← not available (declined in scaffold step)
--- 5. Memory Prune              ← not available (no MEMORY.md)
```

Each pre-check must cite evidence from the freshness matrix. If the evidence is only "file exists," do not pre-check.

---

## Phase 2: Execute (Dependency Order)

Steps run in order because later steps benefit from earlier ones (sync finds MISSING content, refs fixes WRONG patterns).

| Step | Workflow |
|---|---|
| 1. Scaffold | Execute scaffolds selected in 1E, then refresh the freshness matrix |
| 2. GitNexus Reindex | `npx gitnexus analyze --force --embeddings`; report counts |
| 3. Sync Docs | Delegate to `sync` subcommand using changed files from 1B |
| 4. Validate Stale References | Collect doc files; extract concrete claims (paths, function names, counts, env-var names); verify each against codebase; fix in-place |
| 5. Academy Guides | Parse `.academy/README.md` Key Files; cross-ref changed files; update outdated snippets |
| 6. Memory Prune | Delegate to `prune` subcommand |
| 7. Locks (opt) | Delegate to `locks` subcommand |
| 8. Env (opt) | Delegate to `env` subcommand |
| 9. Links (opt) | Delegate to `links` subcommand |
| 10. Secrets (opt) | Delegate to `secrets` subcommand |
| 11. Dead Code (opt) | Delegate to `deadcode` subcommand |
| 12. Lint Drift (opt) | Delegate to `lint-drift` subcommand |

### Doc Size Check (after Step 4)

After validation, count lines in tracked doc files. Soft warnings (do not block):

- Root `CLAUDE.md`: 120 lines
- Child `**/CLAUDE.md`: 25 lines each
- `README.md`: 400 lines
- `docs/**/*.md`: 500 lines
- `AGENTS.md`: 120 lines

Some reference docs (design-system catalogs) legitimately exceed; the warning prompts a conscious choice.

---

## Phase 3: Summary + Optional Commit

Present a consolidated table:

```
| Step | Status | Changes |
|------|--------|---------|
| Freshness Audit | ✓ Done | 2 stale, 3 unknown, 1 missing |
| 1. Scaffold | ✓ Done | Created 2 files |
| 2. GitNexus Reindex | ✓ Done | 812 symbols, 1903 rels |
| 3. Sync Docs | ✓ Done | Updated 3 files |
| 4. Stale References | ✓ Done | Fixed 2 stale paths |
| 5. Academy Guides | ⊘ Skipped | No stale guides |
| 6. Memory Prune | ✓ Done | Removed 4 entries |
| 7. Locks | ✓ Done | No drift |
| 8. Env | ⚠ Found drift | 2 vars missing from .env.example |
```

Offer commit:

```
Commit documentation changes?
  Suggested message: docs: post-change maintenance sync
```

**Critical:** Only stage doc files (`.md`, `.academy/`, `docs/`). NEVER stage `.ts`, `.js`, or other source files. Collect ALL modified `.md` files (including `.env.example`) via:

```bash
git diff --name-only --diff-filter=M -- '*.md' '.env.example'
```

Stage each with explicit `git add <path>`. **Never** use `git add -A`.

After commit, write `last-sync-marker` to `.claude/maintain/last-sync`.

---

## Quality Gate

PASS iff the freshness audit ran and every selected subcommand passes its individual gate. Failure of any single selected subcommand blocks the commit and surfaces the failure to the user.

A `full` run that only checks artifact existence is not a PASS. It must report freshness statuses and ranked recommendations.
