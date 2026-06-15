# Maintainer Communication

Effective communication with maintainers is the difference between merged PRs and abandoned ones. This reference covers response etiquette, feedback handling, and timing.

## Response Timing

| Event | Response window | Action |
|-------|----------------|--------|
| Review comment | Within 48 hours | Acknowledge and address |
| CI failure | Within 24 hours | Fix or explain |
| Merge conflict | Within 48 hours | Rebase |
| "Changes requested" | Within 72 hours | Address all points |
| Approval | Thank the reviewer | Immediate |
| Question from maintainer | Within 48 hours | Answer directly |

After 7 days without response from you, maintainers assume the PR is abandoned. If you need more time, post a comment: "Still working on this — will update by [date]."

## Tone Guidelines

### Do
- Be grateful — they're volunteering their time to review your code
- Be concise — maintainers review many PRs
- Be specific — "I changed X because Y" not "Updated as requested"
- Acknowledge valid points even if you disagree
- Ask questions when feedback is unclear

### Don't
- Argue. If you disagree, explain your reasoning once, then defer to the maintainer.
- Over-apologize. "Good catch, fixed" is better than "I'm so sorry for the mistake, I should have..."
- Tag/ping maintainers to ask for review. They'll get to it.
- Push back on style preferences. Match the project's style, not yours.
- Ghost. If you can't continue, say so.

## Addressing Review Feedback

### For each comment:

1. **Read carefully** — understand what they're asking for
2. **Make the change** — or explain why you didn't
3. **Reply to the comment** — confirm what you did

Reply patterns:
- Simple fix: "Fixed in [commit hash]" or "Done"
- Needs explanation: "Changed to X because [reason]. Let me know if you'd prefer a different approach."
- Disagree: "I see your point about X. I went with Y because [specific reason]. Happy to change if you prefer X."
- Need clarification: "Could you clarify what you mean by X? I want to make sure I address this correctly."

### Batch your responses:
Don't push and reply to each comment individually. Instead:
1. Read ALL review comments
2. Make ALL changes in one batch
3. Push once
4. Reply to all comments
5. Re-request review if the platform supports it

```bash
# After pushing fixes
gh pr review <number> --comment --body "Addressed all feedback. Summary of changes:
- [change 1]
- [change 2]
Ready for another look."
```

## Rebasing During Review

If the maintainer asks you to rebase:

```bash
git fetch upstream
git rebase upstream/<default_branch>
# Resolve any conflicts
git push origin <branch> --force-with-lease
```

Then comment: "Rebased on latest `<default_branch>`. Conflicts resolved in [files]." (Only mention conflicts if there were any.)

## After Merge

Always thank the reviewer:

```bash
gh pr comment <number> --body "Thanks for the review and merge! 🙏"
```

Keep it simple. One line is enough.

Update `.contribute/state.json`:
- Add repo to `contribution_history.repos_contributed_to`
- Increment `total_prs_merged`
- Set `last_contribution` to current date

Clean up:
```bash
# Delete your feature branch
git checkout <default_branch>
git branch -D <feature_branch>
git push origin --delete <feature_branch>

# Sync your fork
git fetch upstream
git merge upstream/<default_branch> --ff-only
git push origin <default_branch>
```

## After Rejection

If a PR is closed without merge:

- Don't take it personally
- Ask for feedback if none was given: "Thanks for reviewing. Any feedback on what could be improved for future contributions?"
- Learn from it and apply to next contribution
- Do NOT reopen a closed PR without explicit invitation

## First-Time Contributor Tips

- Start small. Documentation fixes, typo corrections, and "good first issue" labels exist for a reason.
- Read the entire CONTRIBUTING.md before your first PR.
- Look at recently merged PRs to understand the project's review culture.
- If your first PR is ignored for 2 weeks, a single polite ping is acceptable: "Friendly ping — let me know if this needs any changes."

## `/contribute status` Integration

When running `/contribute status`, check for:

```bash
# Unread review comments
gh pr view <number> --json reviews,comments --jq '
  .reviews[] | select(.state == "CHANGES_REQUESTED") | .body,
  .comments[] | select(.author.login != "<your-user>") | .body
'

# CI status
gh pr checks <number>

# Merge conflicts
gh pr view <number> --json mergeable --jq '.mergeable'
```

Report what needs attention and suggest the appropriate `/contribute respond` action.
