# Issue Triage Rules

How to handle issue mentions and assignments.

## Fetching Issue Context

```bash
# Issue details
gh issue view <number> --repo <owner/repo>

# Issue comments
gh api repos/<owner>/<repo>/issues/<number>/comments

# Issue timeline (events, cross-references)
gh api repos/<owner>/<repo>/issues/<number>/timeline
```

## Mention Response Workflow

When you're mentioned in an issue:

1. **Read the full issue** — title, body, all comments
2. **Identify what's being asked of you**:
   - Bug report needing investigation
   - Feature request needing input
   - Question needing an answer
   - Assignment to fix something
3. **For bug reports**:
   - Check if the repo is available locally
   - Search the codebase for relevant code
   - Determine if you can reproduce or diagnose
   - Draft a response with findings
4. **For feature requests**: draft a response with feasibility assessment
5. **For questions**: draft a direct answer
6. **For assignments**: create a plan and present to user

## Posting Responses

```bash
# Post a comment
gh issue comment <number> --repo <owner/repo> --body "<response>"
```

Always present the draft to the user before posting. Include:
- The issue context (what was asked)
- Your proposed response
- Whether any code changes are needed

## Creating Fix PRs

If the issue requires a code fix:

1. Clone or navigate to the repo locally
2. Create a branch: `git checkout -b fix/issue-<number>-<short-description>`
3. Make the fix
4. Commit with message: `fix: <description> (closes #<number>)`
5. Push and create PR: `gh pr create --repo <owner/repo> --title "<title>" --body "Fixes #<number>"`
6. Link the PR to the issue automatically via `closes #N` in the PR body
