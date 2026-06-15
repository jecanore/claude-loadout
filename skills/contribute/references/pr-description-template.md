# PR Description Template

`/contribute submit` generates a structured PR description. If the project has a PR template, use it. Otherwise, use the default template below.

## Template Detection

Check for project PR templates in order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `PULL_REQUEST_TEMPLATE.md`
4. `.github/PULL_REQUEST_TEMPLATE/` directory (multiple templates)

If found, fill in the project's template sections by mapping:
- "Description" / "Summary" / "What" → Problem + Solution
- "Changes" / "What changed" → Changes list
- "Testing" / "How to test" / "Test plan" → Test plan
- "Related issues" / "Fixes" / "Closes" → Issue link
- Checkboxes → check applicable items

## Default Template

When no project template exists:

```markdown
## Problem
[What is broken or missing. Link to issue.]

Fixes #<issue_number>

## Solution
[What this PR does and why this approach was chosen. Focus on the approach, not a file-by-file list.]

## Changes
- [Grouped by logical change, not per-file]
- [Each bullet describes a cohesive unit of work]

## Test plan
- [ ] [Specific verification steps a reviewer can follow]
- [ ] [Include commands to run if applicable]
```

## Generation Algorithm

### 1. Gather Inputs
```bash
# Diff summary
git diff upstream/<default>...HEAD --stat

# Full diff for analysis
git diff upstream/<default>...HEAD

# Commit messages
git log upstream/<default>..HEAD --format='%s%n%b' --reverse

# Issue body (if linked)
gh issue view <number> --json title,body
```

### 2. Generate Each Section

**Problem:** Extract from issue title + body. If no issue, summarize from commit messages. Always include `Fixes #N` on its own line for GitHub auto-close.

**Solution:** Synthesize from commit messages and diff. Describe the approach and reasoning, not implementation details. One paragraph, 2-4 sentences.

**Changes:** Group related file changes into logical bullets:
- BAD: "Modified `src/auth.js`", "Modified `src/auth.test.js`"
- GOOD: "Added timeout parameter to auth middleware with configurable duration"

Aim for 3-7 bullets. Fewer than 3 suggests the PR might not need a changes section. More than 7 suggests the PR might be too large.

**Test plan:** Generate specific verification steps:
- Include exact commands: "Run `npm test -- --grep 'auth timeout'`"
- Include manual verification: "Start dev server, navigate to /login, verify timeout after 30s"
- Reference CI: "CI runs the full suite — check the `test` job"

### 3. Apply Writing Rules

From the technical-writing skill principles:
- Active voice throughout
- Specific, concrete language (not "improved performance" but "reduced auth latency from 2s to 200ms")
- No puffery (avoid "robust", "seamless", "comprehensive")
- Front-load important information

### 4. Size Guidelines

| Section | Target length |
|---------|--------------|
| Problem | 1-3 sentences |
| Solution | 2-4 sentences |
| Changes | 3-7 bullets |
| Test plan | 2-5 items |
| Total | Under 500 words |

## PR Title

Generate a concise title (under 70 characters):
- Follow project's commit style if conventional: `fix: resolve auth timeout on slow connections`
- Otherwise: imperative mood, lowercase, no period: `add timeout parameter to auth middleware`

## Creating the PR

```bash
gh pr create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<generated body>
EOF
)" \
  --base <upstream_default_branch>
```

After creation:
- Save PR number to `.contribute/state.json`
- Report PR URL to user
- If there are PR dependencies (from state), note them in a comment:
  ```bash
  gh pr comment <number> --body "Depends on #<dep_number> — please merge that first."
  ```
