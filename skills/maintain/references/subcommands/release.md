# Subcommand: `release`

Cut a CHANGELOG release.

## TodoWrite Items

```
- [ ] Check CHANGELOG.md exists; if not, offer to scaffold
- [ ] Load rules/changelog.md
- [ ] Read current [Unreleased] entries
- [ ] If no version provided, suggest one based on entry types
- [ ] Create versioned section: ## [X.Y.Z] - YYYY-MM-DD
- [ ] Move entries from [Unreleased] to versioned section
- [ ] Leave [Unreleased] empty (just heading)
- [ ] Add comparison links at bottom (if git remote)
- [ ] Offer to commit: docs: release vX.Y.Z
```

## Workflow

1. Load `rules/changelog.md`.
2. Check `CHANGELOG.md` exists (if not, offer to scaffold via Step 1 of `scaffold` subcommand; on accept, re-run `release`).
3. Read current `[Unreleased]` entries.
4. If no version provided, suggest based on entry types:
   - Any `Added` → minor bump
   - Only `Fixed`/`Security` → patch bump
   - Breaking changes noted → major bump
5. Create versioned section: `## [X.Y.Z] - YYYY-MM-DD`
6. Move all entries from `[Unreleased]` to the new versioned section.
7. Leave `[Unreleased]` empty (just the heading).
8. Add comparison links at bottom (if git remote configured).
9. Offer to commit: `docs: release vX.Y.Z`.

## Type label

**Rigid** — the Keep-a-Changelog format is well-defined; no judgment required.

## Pre-gate

If no CHANGELOG.md exists, **never** silently skip. Offer to scaffold first; if declined, return early with a clear message: "Cannot release without CHANGELOG.md. Re-run with `/maintain scaffold` first."

## Quality Gate

PASS:
- `[Unreleased]` section is now empty (just the heading).
- New versioned section exists with date and all moved entries.
- Comparison link added (if remote configured).

FAIL:
- Version already exists in CHANGELOG.

Recovery: abort with message; suggest different version.
