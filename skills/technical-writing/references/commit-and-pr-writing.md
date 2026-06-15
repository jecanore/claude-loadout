# Commit Messages & PR Descriptions

Write commit messages and PR descriptions that communicate intent clearly and help future readers understand changes.

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Subject line:**
- Imperative mood: "Add feature" not "Added feature" or "Adds feature"
- 50 characters max
- No period at end
- Capitalize first word

**Body (optional but recommended for non-trivial changes):**
- Wrap at 72 characters
- Explain **why**, not what — the diff shows what changed
- Separate from subject with a blank line

**Footer (optional):**
- Reference issues: "Fixes #123", "Closes #456"
- Note breaking changes: "BREAKING CHANGE: removed X"

### Type Prefixes

| Prefix | When |
|--------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that doesn't fix a bug or add a feature |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `chore` | Build process, tooling, dependencies |

### Good vs Bad Commits

**Good — explains why:**
```
fix(auth): prevent duplicate OTP verification attempts

Users clicking "Verify" rapidly could trigger multiple API calls,
consuming the token on the first call and failing on subsequent ones.
Added debounce and disabled the button during verification.

Fixes #234
```

**Bad — restates the diff:**
```
Updated auth code

Changed the verify function to add a debounce and disable the button.
```

**Bad — too vague:**
```
fix stuff
```

**Bad — too granular (should be one commit):**
```
add debounce to verify button
disable verify button during API call
add loading state to verify button
```

### Commit Scope

When a change touches multiple areas, use the most specific scope:
- `fix(auth): ...` not `fix: auth thing`
- `feat(voice): ...` not `feat: voice pipeline stuff`
- If truly cross-cutting, omit scope: `refactor: extract shared validation`

### When to Commit

- Each commit should be a single logical change
- If you can't summarize it in 50 characters, it's probably too big
- Tests and implementation in the same commit (they're one logical unit)
- Don't commit work-in-progress to shared branches

## Pull Request Descriptions

### Structure

```markdown
## Summary
- [1-3 bullet points explaining what this PR does and why]

## Test plan
- [ ] [Specific test steps or verification checklist]
- [ ] [Include both automated and manual testing]
```

### Good PR Description

```markdown
## Summary
- Add debounce to OTP verify button to prevent duplicate API calls
- Users clicking rapidly consumed the token on first call, causing
  "invalid token" errors on subsequent attempts

## Test plan
- [ ] Tap "Verify" rapidly — only one API call fires
- [ ] Button shows loading state during verification
- [ ] Successful verification still navigates to home
- [ ] Unit tests pass: `npm test -- --grep "OTP"`
```

### PR Title

- Under 70 characters
- Same imperative mood as commits
- Include type prefix if team uses them: `fix(auth): prevent duplicate OTP verification`
- Details go in the body, not the title

### What Makes a Good PR

- **Small and focused** — one logical change per PR
- **Self-reviewing first** — read your own diff before requesting review
- **Links context** — reference issues, Slack threads, or design docs
- **Explains decisions** — if you chose approach A over B, say why
- **Includes test evidence** — screenshots, test output, or manual test steps

### Anti-Patterns

- **Wall of text** — if the description is longer than the diff, reconsider
- **"See commit messages"** — the PR description should stand alone
- **No test plan** — every PR should explain how to verify it works
- **AI puffery in descriptions** — "This groundbreaking refactor seamlessly enhances..." Just state what changed and why.
- **Mixing concerns** — one PR for the bug fix, another for the refactor you noticed along the way

## Changelog Entries

When writing changelog entries (for CHANGELOG.md or release notes):

- **Added** — new features
- **Changed** — changes in existing functionality
- **Fixed** — bug fixes
- **Removed** — removed features
- **Security** — vulnerability fixes

Format: `- [Category]: [What changed] ([#PR](link))`

Example:
```
## [1.2.0] - 2026-02-12
### Added
- Voice input bar with animated mic button (#187)
### Fixed
- OTP verification consuming token on rapid clicks (#234)
### Changed
- Tab bar now uses React Native best practices for layout (#241)
```
