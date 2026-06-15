# Subcommand: `scaffold`

Detect what documentation artifacts exist and offer to create missing ones.

## TodoWrite Items

```
- [ ] Run convention detection (rules/scaffolds.md)
- [ ] Check for each artifact type
- [ ] Present multi-select checklist
- [ ] WAIT for user selection
- [ ] Scaffold selected artifacts using convention-adapted templates
- [ ] Offer single commit: docs: scaffold project documentation
```

## Workflow

1. Run convention detection per `rules/scaffolds.md`.
2. Check for each artifact type:
   - Root CLAUDE.md
   - Child CLAUDE.md (per source subdir)
   - docs/spec/
   - .academy/
   - CHANGELOG.md
   - .gitnexus/ (config only — does not run analyze)
   - MEMORY.md
   - .env.example
   - Lint config (only if missing AND framework detected supports linting)
3. Present a multi-select checklist of missing artifacts.
4. On approval, scaffold using convention-adapted templates from `rules/scaffolds.md`.
5. Offer a single commit: `docs: scaffold project documentation`.

## Convention-adapted templates

`rules/scaffolds.md` provides templates that adapt to:
- Source dir convention (`src/` vs `app/` vs `lib/`)
- Package manager (commands like `npm test` vs `pnpm test`)
- Test runner (vitest/jest/pytest commands)
- Language (typescript-specific vs python-specific scaffolding)
- Framework (next/express/django specifics)

## Type label

**Flexible** — scaffolding is inherently judgment-driven (which artifacts make sense for this repo). Do not over-gate.

## Quality Gate

PASS:
- All selected artifacts created.
- Each is valid markdown / valid config.
- Path conflicts resolved (existing files not overwritten without explicit user confirmation).

FAIL:
- Template generation crashes.
- Path conflict and user did not confirm overwrite.

Recovery: report failures; provide manual creation instructions for failed templates.
