# Graceful Degradation Matrix

The skill works in any repo. Missing artifacts are handled per subcommand. Cell content describes the behavior when the row's artifact is missing.

## Original 7 Subcommands

| Missing | `full` | `sync` | `refs` | `scaffold` | `reindex` | `prune` | `release` |
|---------|--------|--------|--------|-----------|----------|---------|----------|
| `.gitnexus/` | reindex step hidden | — | — | offer scaffold | error + suggest install | — | — |
| `.academy/` | academy step hidden | — | — | offer scaffold | — | — | — |
| CLAUDE.md files | sync scopes to README | scopes to available docs | scopes to available docs | offer scaffold | — | — | — |
| `docs/spec/` | sync scopes to CLAUDE.md | scopes to CLAUDE.md | scopes to CLAUDE.md | offer scaffold | — | — | — |
| No git changes | steps available, none pre-checked | no changes to sync | still runs (pattern-based) | works | works | works | works |
| No MEMORY.md | prune step hidden | — | — | offer scaffold | — | skip | — |
| No CHANGELOG.md | — | creates if changes detected | — | offer scaffold | — | — | offer scaffold first |
| No `package.json` | skip convention detection | skip test count | — | minimal scaffolds | — | — | — |

## New 2026-05 Subcommands

| Missing | `locks` | `env` | `links` | `secrets` | `deadcode` | `lint-drift` |
|---------|---------|-------|---------|-----------|-----------|--------------|
| No lockfile | "no lockfile detected" → skip | — | — | — | — | — |
| No `.env.example` | — | offer scaffold; still scans code | — | — | — | — |
| No env reads in code | — | "no env reads detected" → skip | — | — | — | — |
| No markdown files | — | — | "no md files" → skip | — | — | — |
| No supported toolchain | — | — | — | — | "no supported tool detected" → skip | — |
| No lint config | — | — | — | — | — | "no lint config detected" → skip |
| `.gitignore` blocks scope | scoped to tracked files | scoped to tracked files | scoped to tracked files | scoped to tracked files | scoped to tracked files | scoped to tracked files |

## Universal Conditions

| Condition | All subcommands |
|---|---|
| Merge or rebase in progress | abort any subcommand that edits files; `prune` runs in preview-only mode |
| Detached HEAD | warn; allow read-only subcommands; abort write subcommands unless user confirms |
| Submodules dirty | warn; treat submodule contents as opaque (do not recurse into them) |
| Worktree (linked) | works; convention detection runs against the worktree, not the main checkout |
| Shallow clone | `sync` falls back to `HEAD` (cannot compute long ranges); other subcommands unaffected |

## Rationale

- **Hide rather than fail**: when a step's prerequisites are missing, the picklist hides it instead of failing later. Predictable UX.
- **Offer scaffold rather than crash**: missing artifacts that the skill can create become opt-in scaffolds, not errors.
- **Tracked-files scope**: `.gitignore` rules are honored automatically because we scan via `git ls-files` or repo-relative globs.
- **Read-only safety in degraded states**: when in doubt (merge, detached HEAD), prefer read-only behavior over potential corruption.
