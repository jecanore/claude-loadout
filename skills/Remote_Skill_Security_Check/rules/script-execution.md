# Script Execution Patterns

Detailed patterns for detecting dangerous code execution in remote skill scripts.

## CRITICAL — Dynamic Code Execution

Flag code that executes arbitrary or dynamic content:

- `eval(` — arbitrary JavaScript execution
- `new Function(` — dynamic function creation from string
- `exec(` / `execSync(` — shell command execution
- `child_process.exec(`, `child_process.execSync(`
- `child_process.spawn(` with user/remote input
- `child_process.fork(` with untrusted paths
- `vm.runInNewContext(`, `vm.runInThisContext(` — Node.js VM execution
- `require()` or `import()` with variable/remote path
- `globalThis.eval`, `window.eval`, `global.eval`
- `setTimeout(string)`, `setInterval(string)` — string-based timer execution

## CRITICAL — Pipe-to-Shell

Flag patterns that download and execute remote code:

- `curl ... | sh`
- `curl ... | bash`
- `wget ... -O - | sh`
- `wget ... -O - | bash`
- `curl ... > /tmp/script.sh && sh /tmp/script.sh`
- `npx <unknown-package>` with no version pin
- `node -e "$(curl ...)"`
- `python -c "$(curl ...)"`
- Any pattern: download → write to temp → execute

## HIGH — Unsanitized Input to Shell

Flag scripts that pass user/external input to shell:

- Template literals in exec: `` exec(`command ${userInput}`) ``
- String concatenation in exec: `exec("command " + input)`
- `spawn` with unsanitized arguments from external source
- Shell commands built from environment variables without validation

## HIGH — Script Auto-Execution

Flag skills that require scripts to run automatically:

- `postinstall` scripts in package.json
- Instructions to add scripts to shell profile (`.bashrc`, `.zshrc`)
- Instructions to add cron jobs or launchd agents
- Pre-commit hooks that download and run external code
- `onload` or initialization scripts that run without user action

## MEDIUM — Subprocess Creation

Flag scripts that create subprocesses (may be legitimate):

- `child_process.spawn` with fixed, auditable commands
- `child_process.fork` for known worker scripts
- `cluster.fork()`
- `worker_threads` usage

Note: Subprocess creation is common in build tools. Flag as MEDIUM unless combined with unsanitized input or remote code (then upgrade to HIGH/CRITICAL).

## False Positive Indicators

- Build scripts using `exec` for well-known tools (`tsc`, `eslint`, `prettier`)
- Test runners that spawn child processes
- Skills that use `spawn` with hardcoded, auditable command arrays
- Documentation showing dangerous patterns as examples to avoid (educational)
