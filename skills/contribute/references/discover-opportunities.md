# Discover Contribution Opportunities

## Two Modes

### Mode 1: Dependency Scan (`/contribute discover`)

Scan your project's lockfile for GitHub repos that need help.

**Step 1 — Extract dependencies:**
```bash
# npm/yarn
cat package.json | jq -r '.dependencies, .devDependencies | keys[]'

# Or from lockfile for exact versions
cat package-lock.json | jq -r '.packages | keys[]' | grep -v "^$" | head -100
```

**Step 2 — Resolve to GitHub repos:**
```bash
# For each package, get the repo URL
npm view <pkg> repository.url 2>/dev/null
```

Filter: skip packages without GitHub URLs, skip private registries (catch 404/403 and add to `skipped_deps`), skip non-GitHub hosts (GitLab, BitBucket) with a note.

**Step 3 — Query each repo for opportunities:**
```bash
# Batch with 100ms delay to respect rate limits
gh api repos/OWNER/REPO --jq '{archived, pushed_at, has_issues}'
```

Skip archived repos and repos with no activity in 90 days.

**Step 4 — Surface opportunities (ranked):**

| Priority | Opportunity | Detection |
|----------|------------|-----------|
| 1 | Stale PRs needing rebase | Open >30 days, no author activity, merge conflicts |
| 2 | PRs with failing CI | CI red, last author comment >14 days ago |
| 3 | "help wanted" in your deps | Label match + dep in your lockfile |
| 4 | Issues in repos you've contributed to | Your merged PRs in repo history |
| 5 | "good first issue" in active projects | Label match + recent maintainer activity |

```bash
# Help wanted issues
gh api "repos/OWNER/REPO/issues?labels=help+wanted&state=open&per_page=10"

# Good first issues
gh api "repos/OWNER/REPO/issues?labels=good+first+issue&state=open&per_page=10"

# Stale PRs
gh api "repos/OWNER/REPO/pulls?state=open&sort=updated&direction=asc&per_page=10"
```

### Mode 2: Specific Repo (`/contribute discover owner/repo`)

Same queries as above but targeted at a single repo. Additionally:

```bash
# Check for CONTRIBUTING.md
gh api repos/OWNER/REPO/contents/CONTRIBUTING.md --jq '.download_url' 2>/dev/null

# Check recent maintainer activity
gh api "repos/OWNER/REPO/issues?state=all&per_page=5" --jq '.[].updated_at'

# Check for external merged PRs (open community)
gh api "repos/OWNER/REPO/pulls?state=closed&per_page=20" --jq '[.[] | select(.merged_at != null and .user.type != "Bot")] | length'
```

## Filters

Apply these filters to exclude poor targets:

- **Archived repos:** `archived: true` from API
- **Inactive repos:** No push activity in 90 days (`pushed_at` field)
- **Closed communities:** No CONTRIBUTING.md AND no external merged PRs in last 20 closed PRs
- **Assigned issues:** Respect claims — skip issues with assignees
- **Bot-only repos:** Skip if all recent PRs are from bots (Dependabot, Renovate)

## Edge Cases

### Private dependencies
```bash
# Catch 404/403 gracefully
if ! gh api repos/OWNER/REPO 2>/dev/null; then
  echo "Skipped: private or inaccessible"
fi
```
Add to `skipped_deps` list in report.

### Non-GitHub hosts
Detect from npm registry URL:
- `gitlab.com` → skip with note "GitLab repo — not supported"
- `bitbucket.org` → skip with note "BitBucket repo — not supported"

### Rate limits
- Require `gh auth status` to confirm authentication
- Batch API calls with 100ms delay between repos
- Cache results for 24 hours in `.contribute/discovery-cache.json`

### Monorepos
Detect via `workspaces` field in package.json or `packages/` directory:
```bash
gh api repos/OWNER/REPO/contents/package.json --jq '.content' | base64 -d | jq '.workspaces'
```
Flag discovered issues as `monorepo: true` in output.

## Output Format

Present results as a ranked table:

```
## Contribution Opportunities

### In Your Dependencies (3 found)
| Repo | Opportunity | Type | Link |
|------|------------|------|------|
| lodash/lodash | Fix: Array.flat polyfill | help-wanted | #5123 |
| express/express | Stale PR: Add timeout option | stale-pr | #4891 |
| chalk/chalk | Good first issue: Add RGB support | good-first-issue | #612 |

### Skipped (2)
- `private-pkg`: 404 — private or inaccessible
- `gitlab-pkg`: GitLab repo — not supported

### Rate limit: 42/5000 remaining. Cached at 2024-03-15T10:30:00Z.
```

Label dependencies vs devDependencies separately in the output.
