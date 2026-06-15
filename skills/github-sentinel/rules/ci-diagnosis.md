# CI Diagnosis Rules

How to diagnose CI failures from GitHub Actions logs.

## Log Retrieval

```bash
# Get failed step logs (most useful)
gh run view <run-id> --repo <owner/repo> --log-failed

# Get full run details
gh run view <run-id> --repo <owner/repo>

# Get workflow file
gh api repos/<owner>/<repo>/contents/.github/workflows/<name>.yml
```

## Failure Categories

Parse the failed log output and classify into one of these categories:

### 1. Build Failure
**Signals**: `tsc`, `error TS`, `SyntaxError`, `Cannot find module`, `Build failed`
**Fix strategy**: Read the failing source file, fix the TypeScript/build error, commit and push.

### 2. Test Failure
**Signals**: `FAIL`, `AssertionError`, `expect(`, `test failed`, `vitest`, `jest`
**Fix strategy**: Read the failing test and source code. Determine if the test is wrong or the code is wrong. Fix the appropriate file.

### 3. Lint / Type Check Failure
**Signals**: `eslint`, `prettier`, `tsc --noEmit`, `Type error`
**Fix strategy**: Run the linter/type checker locally, fix all errors.

### 4. Dependency Failure
**Signals**: `npm ERR!`, `ERESOLVE`, `peer dep`, `not found in registry`, `npm ci failed`
**Fix strategy**: Check `package.json` and `package-lock.json`. May need `npm install` to regenerate lock file.

### 5. Docker / Container Failure
**Signals**: `docker build`, `COPY failed`, `RUN failed`, `health check`, `container exited`
**Fix strategy**: Read the Dockerfile. Common issues: missing files in build context, wrong paths, bind address problems, missing env vars.

### 6. Environment / Config Failure
**Signals**: `env`, `secret`, `token`, `GATEWAY_TOKEN`, `API_KEY`, `permission denied`
**Fix strategy**: Check if required env vars are set in the workflow. Check if secrets are configured in repo settings. **Never log or expose secret values.**

### 7. Timeout
**Signals**: `timed out`, `deadline exceeded`, `ETIMEDOUT`, `cancelled`
**Fix strategy**: Increase timeout in workflow, or investigate why the step is slow (e.g., external service down, infinite loop).

### 8. Flaky Test
**Signals**: Same test passes on retry, intermittent failures, race conditions
**Fix strategy**: Identify the flaky test. Common causes: timing dependencies, shared state, network calls in tests. Consider retry or fix the underlying race.

### 9. Workflow Configuration Error
**Signals**: `Invalid workflow file`, `unexpected value`, `required field`, yaml parse errors
**Fix strategy**: Read and fix the workflow YAML. Common issues: indentation, missing required fields, deprecated actions.

### 10. Permissions / Auth Error
**Signals**: `403`, `401`, `Resource not accessible by integration`, `permission denied`
**Fix strategy**: Check workflow `permissions:` block. May need to add specific permissions (e.g., `contents: write`, `packages: read`).

## Diagnosis Output Format

After diagnosing, present:

```
## CI Failure Diagnosis

**Repo**: owner/repo
**Branch**: main
**Workflow**: CI
**Failed Step**: "Run tests"
**Category**: Test Failure

**Root Cause**: Test `auth.test.ts` asserts old behavior after
the token validation change in commit abc1234.

**Suggested Fix**:
- File: `tests/auth.test.ts`, line 42
- Change: Update expected token length from 16 to 24

**Confidence**: High — the error message directly points to the assertion.
```

## Common GitHub Actions Gotchas

- `actions/checkout@v4` defaults to `fetch-depth: 1` (shallow clone) — some tools need full history
- Node.js 20 actions are deprecated as of June 2026 — watch for warning annotations
- `GITHUB_TOKEN` has limited permissions by default — cross-repo operations need a PAT
- Matrix builds: check which matrix combination failed, not just the job name
- Concurrency groups: a cancelled run may not be a real failure (superseded by newer push)
