---
name: contribute
description: >
  Automates the full open source contribution workflow — fork to merge —
  with quality gates at every step. Detects hardcoded count assertions,
  fork contamination, and contribution opportunities in your dependencies.
  Use when contributing to upstream repos, managing forks, or finding issues to work on.
---

# Open Source Contribution Workflow

Manage the entire contribution lifecycle with quality gates that catch real problems: hardcoded test counts that break CI, fork branding that leaks into upstream PRs, and missed maintainer comments.

## Subcommands

| Command | What it does |
|---------|-------------|
| `/contribute discover [owner/repo]` | Find contribution opportunities in your deps or a specific repo |
| `/contribute setup owner/repo` | Fork, clone, detect conventions, create `.contribute/` state |
| `/contribute plan "description"` | Claim issue, investigate root cause, map files, scan for count assertions |
| `/contribute check` | Run all quality gates before submission |
| `/contribute submit` | Create PR with structured description, handle dependencies |
| `/contribute status` | Check CI, reviews, unread comments/mentions |
| `/contribute respond` | Rebase, address feedback, thank reviewer |

## Reference Loading

Only load the reference files needed for the active subcommand:

| Subcommand | References to load |
|-----------|-------------------|
| `discover` | `discover-opportunities.md` |
| `setup` | `setup-workflow.md`, `fork-workflow.md` |
| `plan` | `investigation-gate.md`, `hardcoded-count-detection.md` |
| `check` | `quality-gates.md`, `contamination-scan.md`, `hardcoded-count-detection.md` |
| `submit` | `pr-description-template.md` |
| `status` | *(inline — no reference needed)* |
| `respond` | `maintainer-communication.md`, `fork-workflow.md` |

## Core Rules (Always Active)

### 1. Fork Isolation
Never push to upstream. Always branch from `upstream/<default>`, not `origin/<default>`.

### 2. CONTRIBUTING.md Is Ground Truth
Parse during setup. Every quality gate validates against the upstream project's contribution guidelines.

### 3. Convention Detection
Cache detected conventions to `.contribute/conventions.json`:
- Commit style (conventional, angular, freeform)
- Test command, lint command
- Branch prefix pattern
- CI platform
- Default branch name
- DCO/CLA requirements
- PR template path

### 4. Quality Gate Enforcement
Each subcommand must pass its gate before the next can run:

| Gate | Checked by | Blocks |
|------|-----------|--------|
| Fork configured correctly | `setup` | All other subcommands |
| CONTRIBUTING.md read and parsed | `setup` | `plan`, `check`, `submit` |
| Issue linked and claimed | `plan` | `submit` |
| No duplicate issues/PRs | `plan` | `submit` |
| Tests pass | `check` | `submit` |
| Lint passes | `check` | `submit` |
| No contamination | `check` | `submit` |
| No hardcoded count breakage | `check` | `submit` |
| No secrets in diff | `check` | `submit` |
| DCO/CLA satisfied (if required) | `check` | `submit` |
| New code has tests | `check` | `submit` (warn) |
| Scope is single-concern | `check` | `submit` (warn at multi-concern) |
| Diff under 500 lines | `check` | `submit` (warn at 300, hard-warn at 500) |
| License compatible (new deps) | `check` | `submit` |
| Commits squashed to 1-3 logical | `check` | `submit` (warn) |

### 5. Investigate Before Coding
Always link to an issue and post analysis before writing code. The `plan` subcommand enforces this.

### 6. State Tracking
`.contribute/state.json` persists across sessions:

```json
{
  "upstream": "owner/repo",
  "fork": "myuser/repo",
  "branch": "feat/add-widget",
  "default_branch": "main",
  "related_issue": "#123",
  "pr_number": null,
  "pr_dependencies": [],
  "contamination_patterns": ["my-fork-name", "my-username"],
  "contamination_allowlist": [],
  "detected_count_assertions": [],
  "conventions": {
    "commit_style": "conventional",
    "test_command": "npm test",
    "lint_command": "npm run lint",
    "branch_prefix": "feat/",
    "has_contributing_md": true,
    "has_coc": true,
    "has_pr_template": true,
    "pr_template_path": ".github/PULL_REQUEST_TEMPLATE.md",
    "dco_required": false,
    "cla_required": false,
    "has_changelog": true,
    "ci_platform": "github-actions"
  },
  "contribution_history": {
    "repos_contributed_to": [],
    "total_prs_merged": 0,
    "last_contribution": null
  }
}
```

## Subcommand Workflows

### `/contribute discover [owner/repo]`

**No arguments:** Scan lockfile dependencies for contribution opportunities.
**With argument:** Scan a specific repo for open issues and stale PRs.

Read `references/discover-opportunities.md` for the full algorithm.

### `/contribute setup owner/repo`

1. Fork the repo (or verify existing fork)
2. Clone and configure remotes (`origin` = fork, `upstream` = source)
3. Parse CONTRIBUTING.md, detect conventions
4. Create `.contribute/` directory with state and conventions
5. Display detected conventions and Code of Conduct link

Read `references/setup-workflow.md` and `references/fork-workflow.md`.

### `/contribute plan "description"`

1. Find or create a related issue
2. Verify issue is open and unassigned
3. Check for existing PRs targeting the same issue
4. Claim the issue with a comment
5. Investigate root cause via git history
6. Scan for hardcoded count assertions in test files
7. Post analysis to issue before coding

Read `references/investigation-gate.md` and `references/hardcoded-count-detection.md`.

### `/contribute check`

Run all quality gates. Report pass/fail/warn for each. Block `submit` on any failure.

Read `references/quality-gates.md` and `references/contamination-scan.md`.

### `/contribute submit`

1. Run `/contribute check` automatically (must pass)
2. Generate PR description from diff + issue + commits
3. Use project's PR template if one exists
4. Create PR via `gh pr create`
5. Link to related issue
6. Update `.contribute/state.json` with PR number

Read `references/pr-description-template.md`.

### `/contribute status`

Inline implementation — no reference file needed:

```bash
# Get PR status
gh pr view <pr_number> --json state,statusCheckRollup,reviews,comments

# Check for unread comments
gh pr view <pr_number> --json comments --jq '.comments[] | select(.author.login != "<your-username>")'

# Check CI status
gh pr checks <pr_number>
```

Update the user on: CI pass/fail, pending reviews, unread comments, merge conflicts.

### `/contribute respond`

1. Read new comments and review feedback
2. Rebase on upstream if needed
3. Address each piece of feedback
4. Push updates
5. Reply to reviewer comments
6. Thank the reviewer

Read `references/maintainer-communication.md` and `references/fork-workflow.md`.

## Reference Files

| When You Need | File | ~Tokens |
|---------------|------|---------|
| Dependency scan, stale PR detection | `discover-opportunities.md` | 2,000 |
| Fork setup, convention detection | `setup-workflow.md` | 2,500 |
| Fork/upstream/rebase patterns | `fork-workflow.md` | 1,500 |
| Issue claiming, root cause analysis | `investigation-gate.md` | 1,500 |
| Count assertion scanner | `hardcoded-count-detection.md` | 2,000 |
| Branding leak detector | `contamination-scan.md` | 1,500 |
| Pre-submission check orchestrator | `quality-gates.md` | 2,500 |
| PR body generation | `pr-description-template.md` | 1,000 |
| Response etiquette + feedback | `maintainer-communication.md` | 1,500 |
