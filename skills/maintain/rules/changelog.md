# CHANGELOG.md Rules

Based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Scaffold Template

If CHANGELOG.md doesn't exist, create it:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
```

## Entry Categories

Always use this order. Omit empty categories:

1. **Added** — new features, new files, new capabilities
2. **Changed** — changes to existing functionality, config modifications, refactors
3. **Deprecated** — features marked for future removal
4. **Removed** — deleted features, removed files, dropped support
5. **Fixed** — bug fixes, error corrections
6. **Security** — vulnerability patches, security improvements

## Deriving Entries from Diffs

Map commit prefixes and change types to categories:

| Source | Category |
|--------|----------|
| `feat:` commit message | Added |
| `fix:` commit message | Fixed |
| `refactor:` with behavior change | Changed |
| `chore:` with breaking change | Changed |
| `docs:` commit (skip) | — |
| New exports/files in diff | Added |
| Modified function signatures | Changed |
| Deleted exports/files | Removed |
| Security-related changes | Security |
| Deprecated markers in code | Deprecated |

## Entry Writing Rules

1. **User-facing language**: Describe what changed from the user's perspective, not implementation details
   - Good: "Add extended thinking support for agent mode"
   - Bad: "Add thinkingBudgetTokens to Zod schema in config/index.ts"

2. **Past tense**: Write entries in past tense
   - Good: "Added WebSocket keepalive configuration"
   - Bad: "Add WebSocket keepalive configuration"

3. **One entry per logical change**: Group related file changes into one entry
   - Good: "Added voice pipeline with STT and TTS support"
   - Bad: Three separate entries for stt.ts, tts.ts, and voice handler

4. **Include references**: Add PR/issue numbers when available: `(#42)`, `(fixes #17)`

5. **Be specific**: Include enough detail to understand the change without reading the diff
   - Good: "Added `THINKING_BUDGET_TOKENS` and `THINKING_MAX_TOKENS` environment variables for controlling extended thinking limits"
   - Bad: "Added new config options"

## Unreleased Section Management

- Always append new entries to existing `[Unreleased]` content — never overwrite
- Check for duplicate entries before adding (match by semantic similarity, not exact text)
- If `[Unreleased]` section is empty, add the first category heading and entry

## Release Workflow

When user runs `/maintain release vX.Y.Z`:

1. **Read current `[Unreleased]`** entries
2. **Create versioned section** below `[Unreleased]`:
   ```
   ## [X.Y.Z] - YYYY-MM-DD
   ```
3. **Move all entries** from `[Unreleased]` to the new versioned section
4. **Leave `[Unreleased]` empty** (just the heading, no categories)
5. **Add comparison links** at bottom of file:
   ```
   [Unreleased]: https://github.com/owner/repo/compare/vX.Y.Z...HEAD
   [X.Y.Z]: https://github.com/owner/repo/compare/vPREV...vX.Y.Z
   ```
6. **Suggest version bump** based on entries:
   - Any `Added` → minor bump
   - Only `Fixed`/`Security` → patch bump
   - Breaking changes noted → major bump

If no git remote is configured, skip comparison links.
