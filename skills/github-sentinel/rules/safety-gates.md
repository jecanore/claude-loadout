# Safety Gates

Action classification for GitHub Sentinel. Every action falls into one of three tiers.

## Tier 1: Auto-safe (no confirmation)

These actions are read-only or have no external visibility:

| Action | Command |
|--------|---------|
| Fetch notifications | `gh api notifications` |
| List CI runs | `gh run list` |
| View CI logs | `gh run view --log-failed` |
| View PR diff | `gh pr diff` |
| View PR details | `gh pr view` |
| View issue details | `gh issue view` |
| Read PR comments | `gh api .../comments` |
| Read local code | File reads in any local repo |
| Diagnose failures | Log parsing and analysis |
| Mark notifications read | `gh api notifications/threads/<id> -X PATCH` |
| Check auth status | `gh auth status` |

## Tier 2: Requires confirmation

These actions are visible to others or modify state:

| Action | Command | Confirm prompt |
|--------|---------|---------------|
| Push code | `git push` | "Push {n} commits to {repo}/{branch}?" |
| Create commit | `git commit` | "Commit: {message}?" |
| Post PR comment | `gh pr comment` | "Post this comment on {repo}#{number}?" |
| Post issue comment | `gh issue comment` | "Post this comment on {repo}#{number}?" |
| Submit PR review | `gh pr review` | "Submit {approve/request-changes/comment} review on {repo}#{number}?" |
| Rebase branch | `git rebase && push` | "Rebase {branch} onto {base} and force-push?" |
| Re-run CI | `gh run rerun` | "Re-run failed jobs for run {id}?" |
| Create PR | `gh pr create` | "Create PR: {title}?" |
| Checkout PR branch | `gh pr checkout` | "Switch to PR #{number} branch?" |

**Presentation**: Before each Tier 2 action, show the user exactly what will happen and wait for explicit approval. Group related actions when possible (e.g., "Commit + push fix for CI failure?").

## Tier 3: Never auto-do (always warn)

These actions are destructive or high-impact. Always warn about consequences before asking for confirmation:

| Action | Risk | Warning |
|--------|------|---------|
| Force push | Overwrites remote history | "This will overwrite commits on {branch}. Other contributors may lose work." |
| Delete branch | Irreversible | "This will permanently delete {branch}." |
| Merge PR | Irreversible | "This will merge #{number} into {base}. Cannot be undone without reverting." |
| Close PR | Visible to team | "This will close #{number} without merging." |
| Close issue | Visible to team | "This will close #{number}." |
| Modify repo settings | Admin action | "This changes repository configuration." |

## Cross-Repo Safety

When acting on repos other than the current working directory:

1. **Always confirm the repo name** before any write action: "This will affect {owner/repo}, not the current project."
2. **Never assume local path** — ask the user or verify the path exists
3. **Use `--repo` flag** on all gh commands to be explicit
4. **Avoid `cd`** to other repos silently — inform the user when switching context

## Rate Limiting

- Don't re-run CI more than 3 times for the same commit (likely a real failure, not flaky)
- Don't post more than 5 comments in rapid succession (looks like spam)
- Space out API calls — GitHub rate limits to 5000 requests/hour for authenticated users
