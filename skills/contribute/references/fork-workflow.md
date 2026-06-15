# Fork Workflow Patterns

## Remote Setup

After forking on GitHub, configure two remotes:

```bash
# origin = your fork (push here)
# upstream = source repo (pull from here, never push)
git remote add upstream https://github.com/OWNER/REPO.git
git fetch upstream
```

Verify:
```bash
git remote -v
# origin    https://github.com/YOUR-USER/REPO.git (fetch)
# origin    https://github.com/YOUR-USER/REPO.git (push)
# upstream  https://github.com/OWNER/REPO.git (fetch)
# upstream  https://github.com/OWNER/REPO.git (push)
```

## Branching

Always branch from upstream's default branch, never from `origin/<default>`:

```bash
git fetch upstream
git checkout -b feat/my-change upstream/main
```

This ensures your branch is based on the latest upstream state, not your fork's potentially stale default branch.

## Keeping Your Fork in Sync

```bash
git fetch upstream
git checkout main
git merge upstream/main --ff-only
git push origin main
```

Use `--ff-only` to avoid merge commits on your default branch.

## Rebasing Your Feature Branch

When upstream has new commits:

```bash
git fetch upstream
git rebase upstream/main
```

If conflicts arise:
1. Resolve each conflict
2. `git add <resolved-files>`
3. `git rebase --continue`
4. Repeat until complete

After rebase, force-push to your fork (this is safe — it's YOUR fork):

```bash
git push origin feat/my-change --force-with-lease
```

Use `--force-with-lease` instead of `--force` to avoid overwriting changes you haven't fetched.

## Squashing Commits

Before submitting, squash to 1-3 logical commits:

```bash
# Count commits on your branch
git rev-list upstream/main..HEAD --count

# Interactive rebase to squash
git rebase -i upstream/main
```

In the editor, mark commits as `squash` or `fixup` to combine them. Keep the commit message descriptive.

## PR Branch Updates

When a maintainer requests changes after PR creation:

1. Make changes on your feature branch
2. Commit with a descriptive message
3. Push to your fork: `git push origin feat/my-change`
4. The PR updates automatically

If the maintainer asks you to rebase:
```bash
git fetch upstream
git rebase upstream/main
git push origin feat/my-change --force-with-lease
```

## Common Pitfalls

### Pushing to upstream
Never push to upstream. If `git push upstream` succeeds, your permissions are misconfigured. Fix:
```bash
git remote set-url --push upstream no_push
```

### Stale default branch
If your fork's default branch is behind upstream, sync it before branching:
```bash
git fetch upstream
git checkout main
git merge upstream/main --ff-only
git push origin main
```

### Merge commits in PR
Most projects prefer rebase over merge. If your PR shows merge commits:
```bash
git fetch upstream
git rebase upstream/main
git push origin feat/my-change --force-with-lease
```

### Multiple PRs from same branch
Create separate branches for each PR. Never stack unrelated changes on one branch.
