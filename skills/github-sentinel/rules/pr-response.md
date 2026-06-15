# PR Response Rules

How to handle PR reviews, comments, and requests.

## Fetching PR Context

```bash
# PR overview
gh pr view <number> --repo <owner/repo>

# PR diff
gh pr diff <number> --repo <owner/repo>

# PR checks status
gh pr checks <number> --repo <owner/repo>

# PR review comments (inline on code)
gh api repos/<owner>/<repo>/pulls/<number>/comments

# PR issue-style comments (conversation tab)
gh api repos/<owner>/<repo>/issues/<number>/comments

# PR reviews (approve/request changes)
gh api repos/<owner>/<repo>/pulls/<number>/reviews
```

## Review Request Workflow

When you're requested as a reviewer:

1. **Read the PR description** — understand intent and scope
2. **Read the diff** — focus on:
   - Logic errors and bugs
   - Security issues (injection, auth bypass, secret exposure)
   - Missing error handling at system boundaries
   - Breaking changes to public APIs
   - Test coverage for new code paths
3. **Draft review** — organize feedback by severity:
   - **Blocking**: Must fix before merge (bugs, security, breaking changes)
   - **Suggestion**: Would improve quality but not blocking
   - **Nitpick**: Style/preference, explicitly marked as optional
4. **Present to user** — show the draft review for approval
5. **Post review** on approval:

```bash
# Approve
gh pr review <number> --repo <owner/repo> --approve --body "LGTM — reviewed via GitHub Sentinel"

# Request changes
gh pr review <number> --repo <owner/repo> --request-changes --body "<review body>"

# Comment only (no approval/rejection)
gh pr review <number> --repo <owner/repo> --comment --body "<review body>"
```

## Comment Response Workflow

When someone comments on your PR:

1. **Read the full comment thread** for context
2. **Classify the comment**:
   - **Code change request**: reviewer wants code modified
   - **Question**: reviewer asking for clarification
   - **Discussion**: architectural or design debate
   - **Approval signal**: "LGTM", "looks good", thumbs up
3. **For code changes**:
   - Locate the repo locally
   - Checkout the PR branch: `gh pr checkout <number> --repo <owner/repo>`
   - Make the requested change
   - Commit with message referencing the review: `fix: address review feedback on <file>`
   - Push to the PR branch
   - Reply to the comment confirming the fix
4. **For questions**: draft a clear response, post on approval
5. **For discussions**: present the discussion to the user for their input

## Rebase Workflow

When a PR needs rebasing (merge conflicts or behind base branch):

```bash
# Try the GitHub API first (cleanest)
gh pr update-branch <number> --repo <owner/repo> --rebase

# If that fails (conflicts), do it locally:
gh pr checkout <number> --repo <owner/repo>
git fetch origin main
git rebase origin/main
# Resolve conflicts if any
git push --force-with-lease
```

**Safety**: Always use `--force-with-lease` (not `--force`) to avoid overwriting collaborator commits. If the push is rejected, someone else pushed to the branch — investigate before retrying.

## Response Tone

When posting comments on behalf of the user:
- Be direct and specific — reference file paths and line numbers
- No filler ("Great question!", "Thanks for the review!")
- If the user hasn't specified tone, keep it professional and concise
- Always note when a response was prepared by an AI tool:
  `*Prepared via GitHub Sentinel — verified by [username]*`
