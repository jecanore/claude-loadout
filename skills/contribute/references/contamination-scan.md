# Contamination Scan

Catches fork-specific terms before they reach upstream. Contamination is the #1 cause of embarrassing PR feedback — fork names, usernames, and local paths leaked into upstream code.

## Auto-Detected Patterns

During `/contribute setup`, these patterns are automatically extracted and saved to `state.json`:

| Pattern | Source | Example |
|---------|--------|---------|
| Fork repo name | `git remote get-url origin` | `my-fork-name` |
| Fork owner username | `gh api user --jq '.login'` | `myusername` |
| Upstream repo name | `git remote get-url upstream` | `original-repo` |
| Local absolute paths | Environment | `/Users/myname/`, `/home/myname/`, `C:\Users\myname\` |

The contamination patterns list: `[fork_name, fork_owner, home_directory_prefix]`

If fork name == upstream name (common with GitHub forks), only the owner/username pattern applies.

## Scan Targets

Scan all added/modified lines in the diff:

```bash
git diff upstream/<default>...HEAD
```

**Parse the diff:**
- Only scan lines starting with `+` (added lines)
- Skip diff headers (`+++`, `---`, `@@`)
- Skip binary files
- Skip `node_modules/`, lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`)
- Skip `.contribute/` directory itself

## Severity Levels

| Severity | What | Action |
|----------|------|--------|
| `critical` | LICENSE file changes, secrets (API keys, tokens) | Block submission |
| `error` | Fork name/username in code files (`.js`, `.ts`, `.py`, etc.) | Block submission |
| `warning` | Fork references in docs/comments (may be intentional attribution) | Warn, ask user |
| `info` | Fork name in test fixtures | Note, don't block |

### Severity Assignment Rules

```
IF file is LICENSE* → critical
IF line matches secret pattern (API_KEY=, token=, password=) → critical
IF file extension is code (.js, .ts, .py, .go, .rs, .rb, .java) → error
IF file extension is docs (.md, .txt, .rst) → warning
IF file is in test/ or tests/ or __tests__/ → info
IF file is in fixtures/ or mocks/ or __mocks__/ → info
```

## Special File Handling

### package.json
Only scan identity fields, not the entire file:
- `name` — should match upstream package name
- `author` — should match upstream author
- `repository.url` — should point to upstream
- `homepage` — should point to upstream
- `bugs.url` — should point to upstream

Do NOT flag:
- Dependencies (your fork name might legitimately appear as a dependency during development)
- Scripts (may reference local paths during development — but warn)

### CHANGELOG entries
Always flag as `warning`. CHANGELOG entries almost always contain contamination when contributing upstream — you're writing about the upstream project, not your fork.

### Extension mismatches
If upstream uses `.cjs` and your fork uses `.js` (or vice versa), flag file extension differences in import/require paths as `warning`.

## Allowlist

Users can create `.contribute/contamination-allowlist` with patterns to exclude:

```
# Lines starting with # are comments
# One pattern per line — exact substring match
my-username  # Legitimate attribution in AUTHORS file
```

During scan, skip any match that appears in the allowlist.

### Adding to allowlist
When user confirms a warning is intentional:
```bash
echo "pattern" >> .contribute/contamination-allowlist
```

## Scan Algorithm

```
FOR each line in diff:
  SKIP if not an added line (doesn't start with +)
  SKIP if in excluded path (node_modules, lockfiles, .contribute)

  FOR each contamination_pattern in state.contamination_patterns:
    IF line contains pattern (case-insensitive):
      severity = determine_severity(file_path, line)

      IF pattern in allowlist:
        SKIP

      RECORD {
        file: path,
        line_number: N,
        matched_pattern: pattern,
        severity: severity,
        context: surrounding 2 lines
      }
```

## Output Format

```
## Contamination Scan Results

### Critical (0) — blocks submission
(none)

### Errors (2) — blocks submission
| File | Line | Pattern | Context |
|------|------|---------|---------|
| src/config.js | 42 | `my-fork` | `const repo = "my-fork/project"` |
| src/utils.ts | 18 | `myusername` | `// Author: myusername` |

### Warnings (1) — review needed
| File | Line | Pattern | Context |
|------|------|---------|---------|
| README.md | 5 | `my-fork` | `Based on my-fork implementation` |

→ To allowlist a warning: add pattern to `.contribute/contamination-allowlist`

### Info (0)
(none)
```

## Edge Cases

- **Fork name is a common word** (e.g., "app", "tool"): Too many false positives. Warn during setup and suggest adding to allowlist, or use the full `owner/repo` pattern instead of just the repo name.
- **Username appears in dependency names:** This is why we skip the dependencies section of package.json.
- **Legitimate attribution:** Some projects want contributor names in files. The allowlist handles this.
- **Path style differences:** `~/` vs `$HOME/` — detect both patterns. Also detect Windows paths `C:\Users\`.
- **Case sensitivity:** Match case-insensitively. `MyFork` and `myfork` are both contamination.
