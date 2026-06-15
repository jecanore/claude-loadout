# Freshness Audit Rules

Use during `/maintain full` before any scaffold gate or maintenance picklist. The goal is to answer whether existing maintenance artifacts are current enough to trust, not merely whether they exist.

## Status Vocabulary

Assign exactly one status to each artifact:

| Status | Meaning |
|---|---|
| `missing` | Artifact is absent and the repo would benefit from creating it. |
| `current` | Lightweight checks found no evidence of drift. |
| `stale` | Concrete evidence shows the artifact disagrees with code, config, history, or another artifact. |
| `unknown` | Artifact exists, but the skill did not have enough evidence to prove current or stale. |
| `not-applicable` | Artifact does not apply to this repo shape. |

Do not report an artifact as "already present" without a status. If only existence has been checked, say `unknown`, not `current`.

## Required Read-Only Checks

Run the cheapest applicable checks before asking the user which actions to apply:

| Artifact | Freshness checks |
|---|---|
| `CLAUDE.md`, `AGENTS.md`, `README.md` | Compare recent changed files and commits against documented commands, paths, env vars, service names, test counts, and architecture claims. Flag missing coverage or contradicted claims as `stale`; otherwise `unknown` or `current` depending on evidence. |
| Child AI context files | For each child context file, verify referenced key files still exist and recent changes in that directory are reflected. |
| `.gitnexus/` | Compare index metadata timestamp/commit when available against `HEAD`; if unavailable, report `unknown` and recommend reindex when source files changed. |
| `docs/spec/` | Verify spec directory exists and recent source/schema/config changes have a plausible spec or planning reference. |
| `.academy/` | Verify `.academy/README.md` key files exist and recent changed files overlap with guide key files. |
| `CHANGELOG.md` | Verify `[Unreleased]` exists when using Keep a Changelog; flag if recent non-doc commits are not represented. |
| `MEMORY.md` | Count lines; compare against `AGENTS.md` for duplicates or contradictions when present. |
| `.env.example` | Re-grep runtime env reads and compare to `.env.example`; missing variables are `stale`. |
| Lockfiles | Compare dependency manifests to lockfiles; manifest-only or lockfile-only changes are `stale` candidates. |
| Markdown links | For modified docs and AI context files, validate internal file/anchor links. External links are opt-in only. |
| Lint config | If lint config exists, note changed lint rules since the freshness range and recommend lint-drift when rules changed. |

## Freshness Range

Choose the range in this order:

1. `.claude/maintain/last-sync` or `.Codex/maintain/last-sync` when present and valid.
2. Feature branch: `main...HEAD` or `origin/main...HEAD`.
3. Main branch or no upstream: `HEAD~10..HEAD`.
4. Dirty tree: include uncommitted and staged changes in addition to the chosen commit range.

Record the chosen range in the output.

## Artifact Freshness Matrix

Before any scaffold prompt, present:

```text
| Artifact | Exists | Freshness | Evidence | Recommended action |
|---|---:|---|---|---|
| .env.example | yes | stale | SUPABASE_URL read in code but missing from example | Run env sync |
| CLAUDE.md | yes | unknown | Exists; no doc-vs-code check selected yet | Run sync docs |
| MEMORY.md | no | missing | No MEMORY.md found | Optional scaffold |
```

## Recommended Action Ranking

Use the matrix to pre-rank the maintenance picklist:

| Rank | Condition | Action |
|---|---|---|
| High | Artifact is `stale`, source/config changed, or concrete drift found | Pre-check the relevant subcommand. |
| Medium | Artifact is `unknown` but related files changed recently | Suggest but do not require. |
| Optional | Artifact is `missing` but not required for drift detection | Offer scaffold after audit findings. |
| Not needed | Artifact is `current` or `not-applicable` | Leave unchecked with evidence. |

## Scaffold Gate Position

Missing artifacts are never allowed to block freshness analysis. Run freshness checks first, then present optional scaffolding for missing artifacts. The wording must make this clear:

```text
Optional missing artifacts detected after freshness audit. Select which to scaffold, or "none" to continue.
```

## Audit vs Apply

`/maintain full` is audit-first:

1. Discover artifact existence.
2. Audit freshness/readiness with read-only checks.
3. Present ranked recommended actions.
4. Ask which actions to apply.
5. Execute only selected actions.

If the user asks for "audit only", stop after step 3.
