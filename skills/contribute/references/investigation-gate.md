# Investigation Gate

Before writing any code, `/contribute plan` runs a structured investigation. This prevents wasted effort on claimed issues, duplicate PRs, and coding without understanding root cause.

## Step 1: Verify Issue Is Open and Unassigned

```bash
gh issue view <number> --json state,assignees,labels,title,body
```

**Checks:**
- `state == "OPEN"` — if closed, stop and report
- `assignees` is empty — if assigned, warn user and ask whether to proceed
- No "wontfix" or "duplicate" labels

If no issue number is provided, search for an existing one:
```bash
gh issue list --search "<description>" --state open --limit 5
```

Present matches and let the user pick or create a new issue.

## Step 2: Check for Existing PRs

```bash
# Search for PRs referencing this issue
gh pr list --search "fixes #<number>" --state open --limit 5
gh pr list --search "closes #<number>" --state open --limit 5
gh pr list --search "#<number>" --state open --limit 10
```

If existing PRs found:
- Show them to the user
- If any are active (author responded within 14 days), recommend waiting or asking to collaborate
- If all are stale (no activity >30 days), note they may be abandoned

## Step 3: Claim the Issue

Post a comment to claim the issue:

```bash
gh issue comment <number> --body "I'd like to work on this. Here's my initial analysis:

**Root cause:** [to be updated after investigation]
**Approach:** [to be updated after investigation]
**Estimated scope:** [to be updated after investigation]

I'll update this comment with findings before submitting a PR."
```

The message is configurable. Some communities prefer "I'm interested in working on this" without technical details upfront.

## Step 4: Investigate Root Cause

### 4a. Map affected files
```bash
# Find files related to the description
# Use grep/glob based on keywords from the issue
```

### 4b. Git history analysis
```bash
# Recent changes to affected files
git log --oneline -20 -- <files>

# Who last touched these files
git blame <file> | head -30

# When was this area last changed
git log --oneline --since="6 months ago" -- <directory>
```

### 4c. Trace the bug (if applicable)
- Read error messages from the issue
- Find the error string in code
- Trace backwards to find root cause
- Check if there's a related test that should have caught this

### 4d. Identify scope
- List all files that need changes
- Identify if changes cross module boundaries
- Check if a test file exists for the affected code
- Note if CHANGELOG needs updating

## Step 5: Scan for Count Assertions

If your planned change ADDS or REMOVES files, trigger the hardcoded count detection algorithm (see `hardcoded-count-detection.md`). This catches:
- Test files that assert a specific number of agents, commands, plugins, etc.
- Arrays that enumerate expected file names
- `readdirSync` results compared against numeric literals

## Step 6: Post Analysis to Issue

Update the claiming comment with findings:

```bash
gh issue comment <number> --body "## Investigation Results

**Root cause:** [specific explanation]
**Affected files:** [list]
**Approach:** [what you plan to change and why]
**Risks:** [what could break, edge cases]
**Count assertions found:** [any hardcoded counts that need updating]

I'll submit a PR shortly."
```

Posting analysis before coding:
- Shows maintainers you've done homework
- Gets early feedback on approach before investing time
- Builds trust with the project
- Documents the investigation for future contributors

## Output

After investigation, save to `.contribute/state.json`:
- `related_issue`: issue number
- `detected_count_assertions`: any found by the scanner
- Investigation summary for PR description generation later

Present to user:
1. Issue status and any warnings
2. Existing PR check results
3. Root cause analysis
4. Affected file list
5. Count assertion warnings
6. Recommended next steps
