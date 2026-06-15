# Rule: dead-code

Tool selection and false-positive filtering for dead-code detection. Loaded by [`/maintain deadcode`](../references/subcommands/deadcode.md).

## Tool Selection by Language

### TypeScript / JavaScript

**Primary: knip** (https://knip.dev)
- Detects: unused files, unused exports, unused dependencies, unused types, unused devDependencies.
- Run: `npx knip --reporter json`
- Confidence: high for unused files; high for unused dependencies; medium for unused exports (DI/dynamic concerns).

**Fallback: ts-prune**
- Older, simpler. Detects unused exports only.
- Run: `npx ts-prune --error`
- Confidence: medium.

### Python

**Primary: vulture**
- Run: `vulture <src> --min-confidence 80`
- Built-in confidence scoring (60–100 scale).
- Treat ≥ 90 as **high**, 80–89 as **medium**, < 80 as **low**.

**Fallback: pyflakes**
- Detects unused imports only (subset of vulture's coverage).

### Ruby

**Primary: debride**
- Run: `debride <src>`
- Conservative; metaprogramming produces false positives.
- Default all findings to **medium** confidence; rarely high.

### Rust

**Primary: cargo-udeps** (requires nightly)
- Run: `cargo +nightly udeps`
- Only detects unused dependencies (not unused functions; rustc warnings cover those via `dead_code` lint).

**For unused symbols:** rely on `#[warn(dead_code)]` from rustc. Re-run `cargo build` and parse warnings.

### Go

**Primary: staticcheck**
- Run: `staticcheck -checks U1000 ./...` for unused symbols.
- Confidence: high (Go's strict export rules make detection reliable).

## Confidence Heuristics

Apply on top of tool's own scoring:

| Pattern | Adjusted confidence |
|---|---|
| Unused export in package marked `"private": true` | upgrade to high |
| Unused export with `// @public` JSDoc tag | demote to low |
| Symbol referenced only by string in JSON config | low (might be DI) |
| Symbol matches framework convention name | low — see Framework Conventions below |
| Test-only utility used by tests in another workspace | medium → low if cross-workspace |
| Default export of file matching framework page route | low (entry point, not unused) |

## Framework Conventions (do not flag as dead)

These names are dynamically loaded by frameworks; static analysis can't see the reference:

- **Next.js**: `default` export of `pages/**/*.{ts,tsx,js,jsx}`, `app/**/page.{ts,tsx,js,jsx}`, `app/**/layout.*`, `app/**/loading.*`, `app/**/error.*`, `app/**/not-found.*`, `getServerSideProps`, `getStaticProps`, `getStaticPaths`, `generateMetadata`, `generateStaticParams`, `middleware`, `NextConfig` default export.
- **Remix**: `loader`, `action`, `meta`, `links`, `headers`, `default` export of `routes/**`.
- **Astro**: `default` export of `pages/**/*.astro`, `getStaticPaths`.
- **SvelteKit**: `load`, `actions`, `default` export of `+page.svelte`, `+layout.svelte`.
- **Express middleware** (heuristic): `default` export of files imported via `app.use(...)` strings.
- **Pytest**: functions starting with `test_`.
- **Django**: `urlpatterns`, view classes named in URL patterns.
- **Rails**: subclasses of `ApplicationController`, `ApplicationRecord`, `ApplicationJob`, `ApplicationMailer`.

## Allowlist Format

`.claude/maintain/deadcode-allowlist.txt`:

```
# Format: <file-glob> <symbol-or-glob> [optional comment]
src/legacy/**           *                    # legacy module — preserve all exports
src/types/api.ts        ApiVersion           # consumed by external SDK package
src/utils/registry.ts   register*            # all register* fns are DI-loaded
```

## Edit Strategy

When user approves deletion:
1. Group by file.
2. Per file, present full diff via Edit tool plan.
3. Wait for per-file approval (or batched-OK).
4. Apply edits.
5. **Run lint** — if it fails, REVERT and surface error.
6. **Run build/test** — if it fails, REVERT and surface error.
7. Only then offer to commit.

Revert path: keep the original file content captured before Edit; on failure, Write the original back.

## Never

- Auto-delete any symbol.
- Delete a symbol with low confidence without explicit user approval per-symbol.
- Skip the post-deletion lint+build verification.
- Delete from `dist/`, `build/`, `node_modules/`, `vendor/`, or any generated directory.
