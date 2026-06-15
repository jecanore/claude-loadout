# Setup Workflow

`/contribute setup owner/repo` prepares your local environment for contributing.

## Step 1: Fork the Repository

```bash
# Check if fork already exists
gh repo view YOUR-USER/REPO 2>/dev/null

# If not, fork it
gh repo fork OWNER/REPO --clone=false
```

If a fork already exists, skip forking and confirm the user wants to use the existing one.

## Step 2: Clone and Configure Remotes

```bash
# Clone your fork
gh repo clone YOUR-USER/REPO

# Add upstream remote
cd REPO
git remote add upstream https://github.com/OWNER/REPO.git
git fetch upstream

# Prevent accidental pushes to upstream
git remote set-url --push upstream no_push

# Verify
git remote -v
```

If already cloned (detected via `git remote -v`), just verify and fix remotes.

## Step 3: Detect Default Branch

```bash
# Get upstream default branch
gh api repos/OWNER/REPO --jq '.default_branch'
```

Save as `default_branch` in state. Common values: `main`, `master`, `develop`.

## Step 4: Parse CONTRIBUTING.md

```bash
# Check for CONTRIBUTING.md in common locations
gh api repos/OWNER/REPO/contents/CONTRIBUTING.md 2>/dev/null
gh api repos/OWNER/REPO/contents/.github/CONTRIBUTING.md 2>/dev/null
gh api repos/OWNER/REPO/contents/docs/CONTRIBUTING.md 2>/dev/null
```

If found, download and parse for:

### Commit Style
Search for keywords:
- "Conventional Commits" or "feat:", "fix:" → `conventional`
- "Angular" or "type(scope):" → `angular`
- No specific format mentioned → `freeform`

### Test Command
Search for:
- `npm test`, `yarn test`, `pnpm test`
- `make test`, `cargo test`, `go test`, `pytest`
- Custom commands mentioned in "Testing" or "Running tests" sections

### Lint Command
Search for:
- `npm run lint`, `yarn lint`
- `make lint`, `cargo clippy`, `golint`

### Branch Naming
Search for:
- "branch naming" or "branch format"
- Common patterns: `feat/`, `fix/`, `feature/`, `bugfix/`
- If not specified, default to `feat/` for features, `fix/` for bugs

### DCO/CLA Requirements
Search for:
- "Signed-off-by" or "DCO" or "Developer Certificate" → `dco_required: true`
- "CLA" or "Contributor License Agreement" → `cla_required: true`
- Neither → both false

### PR Template
```bash
# Check for PR template
gh api repos/OWNER/REPO/contents/.github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
gh api repos/OWNER/REPO/contents/.github/pull_request_template.md 2>/dev/null
gh api repos/OWNER/REPO/contents/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

## Step 5: Detect CI Platform

```bash
# Check for CI config files
gh api repos/OWNER/REPO/contents/.github/workflows 2>/dev/null && echo "github-actions"
gh api repos/OWNER/REPO/contents/.travis.yml 2>/dev/null && echo "travis"
gh api repos/OWNER/REPO/contents/.circleci 2>/dev/null && echo "circleci"
gh api repos/OWNER/REPO/contents/Jenkinsfile 2>/dev/null && echo "jenkins"
gh api repos/OWNER/REPO/contents/.gitlab-ci.yml 2>/dev/null && echo "gitlab-ci"
```

## Step 6: Check for Code of Conduct

```bash
gh api repos/OWNER/REPO/contents/CODE_OF_CONDUCT.md 2>/dev/null
gh api repos/OWNER/REPO/contents/.github/CODE_OF_CONDUCT.md 2>/dev/null
```

If found: `has_coc: true`. Display to user: "This project has a Code of Conduct. Review: [link]"

## Step 7: Check for CHANGELOG

```bash
gh api repos/OWNER/REPO/contents/CHANGELOG.md 2>/dev/null
gh api repos/OWNER/REPO/contents/CHANGES.md 2>/dev/null
gh api repos/OWNER/REPO/contents/HISTORY.md 2>/dev/null
```

## Step 8: Build Contamination Patterns

```bash
# Fork owner
FORK_OWNER=$(gh api user --jq '.login')

# Fork repo name (may differ from upstream)
FORK_NAME=$(basename $(git remote get-url origin) .git)

# Upstream repo name
UPSTREAM_NAME=$(basename $(git remote get-url upstream) .git)

# Home directory
HOME_DIR=$HOME
```

Contamination patterns: `[FORK_NAME, FORK_OWNER, HOME_DIR]`

If `FORK_NAME == UPSTREAM_NAME`, drop the repo name from patterns (it's not contamination).

## Step 9: Create `.contribute/` Directory

```bash
mkdir -p .contribute
```

Write `state.json` with all detected values. Write `conventions.json` as a convenience alias.

Add `.contribute/` to `.gitignore` if not already present (this is local state, not for upstream).

## Step 10: Present Summary

Display to user:

```
## Setup Complete: OWNER/REPO

| Setting | Value |
|---------|-------|
| Fork | YOUR-USER/REPO |
| Default branch | main |
| Commit style | conventional |
| Test command | npm test |
| Lint command | npm run lint |
| CI | github-actions |
| DCO required | no |
| CLA required | no |
| Has CONTRIBUTING.md | yes |
| Has Code of Conduct | yes |
| Has PR template | yes |
| Has CHANGELOG | yes |

Contamination patterns: my-fork, myusername, /Users/myname
Code of Conduct: https://github.com/OWNER/REPO/blob/main/CODE_OF_CONDUCT.md

Next: `/contribute plan "description"` to claim an issue and investigate.
```

## Fallback Behavior

If CONTRIBUTING.md doesn't exist:
- Warn: "No CONTRIBUTING.md found. Using defaults. Check project README for contribution guidelines."
- Set `has_contributing_md: false`
- Use sensible defaults (conventional commits, `npm test`, etc.)
- Still allow proceeding — not all projects have one

If the project has no CI:
- Set `ci_platform: null`
- Warn: "No CI detected. Run tests manually before submitting."
