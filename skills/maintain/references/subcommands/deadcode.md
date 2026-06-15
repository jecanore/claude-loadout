# Subcommand: `deadcode` (new 2026-05)

Identify unreachable exports / unused code via language-appropriate tooling. Always present results; **never auto-delete**.

## TodoWrite Items

```
- [ ] Detect language(s) and pick tool(s) per workspace (rules/dead-code.md)
- [ ] If no supported toolchain detected, surface skip; STOP
- [ ] Run tool(s) per workspace; capture results
- [ ] Filter known false-positive patterns
- [ ] Annotate confidence (high/medium/low) per finding
- [ ] Present report grouped by workspace and confidence
- [ ] On approval, generate Edit/Write plan; surface diff; WAIT for user approval per file
- [ ] After deletion, run lint + build; abort and revert on failure
```

## Tool Selection

Load `rules/dead-code.md`:

| Language | Primary tool | Fallback | Notes |
|---|---|---|---|
| TypeScript | `knip` | `ts-prune` | knip catches more (files, deps, exports); ts-prune is older but stable |
| JavaScript | `knip` | — | Tree-shaking-aware analyzers preferred |
| Python | `vulture` | `pyflakes` (with `--unused-import` flag) | vulture has confidence scoring built in |
| Ruby | `debride` | — | conservative; many false positives on metaprogramming |
| Rust | `cargo +nightly udeps` | (warn: heavy operation) | requires nightly; nightly may not be present |
| Go | `staticcheck` (with `U1000`) | — | built-in unused detector |

If primary tool not installed:
1. Suggest install command (`npm i -D knip` etc.).
2. Offer to fall back to a simpler grep-based heuristic with explicit confidence warning.
3. Never run a fallback that produces high false-positive output without warning the user.

## Confidence Scoring

| Confidence | Criteria |
|---|---|
| **high** | Exported symbol with no internal or external references; not in public API surface; not a default export of a route/page module. |
| **medium** | Symbol referenced only in tests or via dynamic import; possibly entry point. |
| **low** | Default exports of dynamic modules; classes referenced by string in DI containers; symbols matching framework conventions (`getServerSideProps`, `loader`, `action`). |

## False-Positive Filters

Filter automatically:
- Default exports of files that match framework conventions (Next.js page modules, Remix routes, Astro pages).
- Symbols listed in `package.json` `exports` field or `main`/`module` entries.
- Symbols matching `__*__` (dunder) pattern in Python.
- Re-exports in barrel files when the re-exported symbol is itself used.
- Symbols listed in `.claude/maintain/deadcode-allowlist.txt`.

## Edit Strategy — NEVER AUTO-DELETE

Auto-deletion fails when:
- The symbol is consumed by an external package depending on this one.
- Runtime `require()` / `import()` / DI string references aren't statically detectable.
- Tests in another workspace depend on the symbol.

**Always**:
1. Present per-file deletion plan.
2. Show the symbols and their confidence.
3. Wait for user approval per file (or per batch).
4. After deletion, run lint + build (or test) **before** committing.
5. If lint/build fails, revert the deletion and surface the error.

## Type label

**Flexible** — confidence scoring is heuristic; user judgment required.

## Quality Gate

PASS:
- Tool ran successfully.
- Findings presented with confidence scores.
- (If user approved deletions) post-deletion lint + build pass.

FAIL:
- Auto-deletion without user approval.
- Lint/build broken after deletion (must revert).

## Verification §F (lives in rules/verification.md)

```
1. Re-run dead-code tool.
2. Assert: any high-confidence finding from last run is either gone (deleted) or in allowlist.
3. Run lint and build; both must pass.
```
