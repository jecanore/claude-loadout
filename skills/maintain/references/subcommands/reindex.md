# Subcommand: `reindex`

GitNexus reindex only. Thin wrapper around the GitNexus CLI.

## TodoWrite Items

```
- [ ] Check GitNexus availability (.gitnexus/ exists OR npx gitnexus runs)
- [ ] If unavailable, surface error + install suggestion; STOP
- [ ] Run npx gitnexus analyze --force --embeddings
- [ ] Report symbol count, relationship count, execution flow count
```

## Workflow

1. Check `.gitnexus/` exists or `npx gitnexus --version` succeeds.
2. If not available: "GitNexus not found. Install with `npm i -D gitnexus` to enable."
3. Run: `npx gitnexus analyze --force --embeddings`
4. Report:
   - Symbol count
   - Relationship count
   - Execution flow count
   - Time elapsed

## Type label

**Rigid** in the trivial sense — there's only one way to invoke the tool. The wrapper exists so other subcommands can compose against it consistently.

## Quality Gate

PASS:
- Exit 0
- Symbol count > 0

FAIL:
- Exit non-zero
- Tool not installed

Recovery: report error; suggest install command; do not retry automatically.
