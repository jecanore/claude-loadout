# Change Detection Rules

## Git Commands by Input Mode

| Mode | Command | Notes |
|------|---------|-------|
| Uncommitted | `git diff` | Working tree vs index |
| Staged | `git diff --staged` | Index vs HEAD |
| Single commit | `git show <sha> --stat` + `git show <sha>` | Full diff + file list |
| Range | `git diff <range>` + `git log --oneline <range>` | Diff + commit messages |

Always also run `git diff --stat <range>` to get the file-level overview for new/deleted file detection.

## Detection Patterns

### Environment Variables
```
# In .env.example diffs:
+SOME_VAR=value              → new env var

# In source code diffs:
+process.env.SOME_VAR        → new env var reference
+.*z\.string\(\).*           → new Zod config field (check field name)
+.*z\.number\(\).*           → new Zod config field
+.*z\.boolean\(\).*          → new Zod config field
+.*\.default\(.*\)           → default value for config field
```

### Function Signatures
```
# New or changed parameters:
-function foo(a: string)
+function foo(a: string, b?: number)    → new optional parameter

# Changed in export:
-export function handleX(config, logger)
+export function handleX(config, logger, options?)  → new parameter
```

### Dependencies
```
# In package.json diffs:
+"new-package": "^1.0.0"     → new dependency
-"old-package": "^1.0.0"     → removed dependency
-"package": "^1.0.0"
+"package": "^2.0.0"         → version bump
```

### Test Changes
```
# New test files in diff --stat:
tests/new-feature.test.ts    → new test file

# New test cases in diff:
+  it('should ...             → new test case
+  test('should ...           → new test case
+  describe('...              → new test suite
```

### Security Changes
```
# Rate limit modifications:
+/-  .*rateLimit.*            → rate limit change
+/-  .*maxPayload.*           → payload limit change
+/-  .*allowedOrigins.*       → origin policy change

# Auth changes:
+/-  .*token.*validate.*      → auth validation change
+/-  .*auth.*                 → auth logic change
```

## Categorization Rules

1. **Prefer specific over general**: A `process.env.X` addition in `config/index.ts` is `env_var`, not `config`
2. **One change, multiple types**: A new file containing a new env var produces both `new_file` and `env_var` entries
3. **Refactor detection**: If a function moved between files but signature unchanged, it's not a `function_sig` change — check both old and new paths
4. **Formatting-only**: If a file's diff is only whitespace/formatting, skip it entirely

## Large Diff Handling (100+ files)

Tier by impact:
1. **Full analysis**: config/, schema files, protocol files, package.json, .env.example
2. **Hunk-level scan**: src/ logic files — scan for signature changes, new exports
3. **Skip**: Auto-generated files, lock files, formatting-only changes

## Output Format

Produce a list of change entries:
```
{ type: 'env_var', file: 'src/config/index.ts', line: 42, description: 'New THINKING_BUDGET_TOKENS config field with default 10000' }
{ type: 'function_sig', file: 'src/llm/anthropic.ts', line: 88, description: 'handleChatSend gained optional thinking parameter' }
```
