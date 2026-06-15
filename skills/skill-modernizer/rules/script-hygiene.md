# Script Hygiene — Validation rules for `scripts/` in target skills

**Loaded by:** `audit` (when target has `scripts/`), `modernize` (when target
has `scripts/`)

**Version:** 1.0

---

## Purpose

When a target skill ships executable code in a `scripts/` directory, audit
this code against a focused safety baseline. Reference-only skills do not
have scripts and this rule does not apply to them; the audit pipeline skips
loading this file.

The checks below are pragmatic, not exhaustive. They catch the most common
shipping hazards without growing into a general-purpose linter. Vendor-
specific patterns are out of scope.

---

## Checked files

A "script" for the purpose of this rule is any file under `scripts/` (or any
sibling directory commonly used for executables — `bin/`, `scripts/lib/`)
that meets at least one of:

- Has an executable extension: `.sh`, `.bash`, `.py`, `.js`, `.mjs`, `.ts`,
  `.rb`.
- Has no extension but starts with a `#!` shebang.

Files that match neither (e.g., `.md`, `.json`, `.txt`) are ignored by this
rule. They may still be flagged by other rules (e.g., secret scan) when
appropriate.

---

## Rule 1 — Shebang present and matches extension

**Check:** every script has a `#!` line as line 1, and the interpreter is
consistent with the file extension.

**Reference table:**

| Extension | Required shebang |
|---|---|
| `.sh`, `.bash`, no extension (bash) | `#!/usr/bin/env bash` |
| `.py`        | `#!/usr/bin/env python3` |
| `.js`, `.mjs`| `#!/usr/bin/env node` |
| `.ts`        | `#!/usr/bin/env -S npx tsx` (or vendor-equivalent) |
| `.rb`        | `#!/usr/bin/env ruby` |

**Status mapping:**

- `ok` — shebang present and matches the table.
- `warn` — shebang present but uses an absolute interpreter path
  (`#!/bin/bash`) instead of `env`. Portable variant preferred but the
  script is functional.
- `fail` — shebang missing entirely, OR shebang interpreter mismatches the
  file extension (e.g., `.py` with `#!/usr/bin/env node`).

**Note in finding:** for `warn`, suggest the env-prefixed equivalent. For
`fail`, give the exact line to insert.

---

## Rule 2 — Error handling

**Check:** the script propagates errors instead of silently continuing.

**Per-language acceptance:**

- **Bash:** `set -euo pipefail` near the top (after the shebang and any
  comment block). Variants accepted: each flag set on a separate line, or
  any superset like `set -Eeuo pipefail`.
- **Python:** I/O calls are wrapped in `try` / `except` (or in a function
  whose surrounding caller catches), and the script does not swallow
  exceptions with bare `except:` clauses. A single `if __name__ == "__main__"`
  block that calls `sys.exit(main())` is recommended; not required.
- **Node / TypeScript:** the script either uses top-level `await` with
  unhandled rejections allowed to crash, or wraps the entry point with a
  `.catch(err => { process.exit(1); })`. A bare `process.on('unhandledRejection', ...)`
  that logs and continues is **not** sufficient.

**Status mapping:**

- `ok` — language-appropriate error handling present.
- `warn` — partial (e.g., bash has `set -e` but not `pipefail`; python has
  some try/except but also at least one bare `except:`).
- `fail` — no error handling at all; errors are silently swallowed or
  ignored.

---

## Rule 3 — No hardcoded secrets

**Check:** scan the script body for patterns that strongly suggest a
hardcoded credential. The set is intentionally focused; broader scans belong
in dedicated secret-scanning tooling.

**Patterns flagged:**

```regex
# Provider API key prefixes
sk-[A-Za-z0-9]{20,}
sk_(live|test)_[A-Za-z0-9]{20,}
pk_(live|test)_[A-Za-z0-9]{20,}
xoxb-[0-9]+-[0-9]+-[A-Za-z0-9]{20,}    # Slack bot token
xoxp-[0-9]+-[0-9]+-[0-9]+-[A-Za-z0-9]{20,}  # Slack user token

# AWS access key
AKIA[0-9A-Z]{16}

# Generic high-entropy literal patterns
(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*['"][A-Za-z0-9_\-+/=]{16,}['"]

# Private keys
-----BEGIN\s+(RSA|OPENSSH|DSA|EC|PGP)\s+PRIVATE\s+KEY-----

# JWT-shaped tokens (header.payload.signature, base64url chunks)
eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
```

**Status mapping:**

- `ok` — no patterns matched.
- `warn` — pattern matched inside a comment line or in a documented test
  fixture. Surface the line and let the user decide; do not auto-suppress.
- `fail` — pattern matched in active code.

**Note in finding:** include the file and line number. Never include the
matched substring in output (it would leak the secret into logs / reports);
quote a redacted form instead.

---

## Rule 4 — Exec permissions on shebang'd scripts

**Check:** any file with a `#!` line on line 1 must have the executable bit
set for at least the user.

**Detection:** `stat`-style check (or `Bash` invocation of `test -x`).

**Status mapping:**

- `ok` — executable bit set.
- `warn` — shebang present, executable bit not set, but file is invoked via
  an explicit interpreter elsewhere in the skill (e.g., `bash scripts/foo.sh`).
- `fail` — shebang present, executable bit not set, no explicit interpreter
  invocation found.

**Suggested fix:** `chmod +x <path>` and a one-line note that the user
should commit the mode change.

---

## Rule 5 — Reasonable dependency declarations

**Check:** the script does not perform implicit dependency installation
mid-execution. Dependencies are either:

- Declared in a manifest (`requirements.txt`, `pyproject.toml`,
  `package.json`, `Gemfile`) at the skill root or `scripts/` root, or
- Listed in a top-of-file comment block as a docstring/comment, or
- Installed via an explicit setup step the user runs before invoking the
  script (documented in SKILL.md or `scripts/README.md`).

**Patterns flagged as implicit installs:**

```regex
# Inline pip install
^\s*(pip|pip3)\s+install\s+
^\s*python\s+-m\s+pip\s+install\s+
import\s+subprocess.*pip.*install

# Inline npm install
^\s*npm\s+install\s+
^\s*npx\s+--yes\s+\S+

# Inline gem install
^\s*gem\s+install\s+
```

**Status mapping:**

- `ok` — no implicit installs detected; manifest or comment-block declares
  dependencies.
- `warn` — implicit install present but guarded by an `if not installed`
  check. Functional but fragile.
- `fail` — implicit install present without a guard, OR the script imports
  packages not declared anywhere.

**Note in finding:** suggest the appropriate manifest location based on
language detected, or a comment-block format like:
```
# Requires: requests>=2.31, click>=8.1
```

---

## Aggregate emission

For each script under `scripts/`, the audit emits one row per rule (5 rows
per script). Findings collect in `audit.scriptHygiene` per the state schema:

```ts
interface ScriptHygieneFinding {
  file: string;
  rule: "shebang" | "error-handling" | "secret-scan" | "exec-perm"
      | "deps-declared";
  status: "ok" | "warn" | "fail";
  note: string;
}
```

The audit report's `Script hygiene` block prints one line per finding, with
columns `File | Rule | Status | Note`. Files where every rule is `ok` are
collapsed to a single summary line:

```
scripts/build.sh    all rules ok
```

---

## Checklist row schema (audit output)

When the target has `scripts/`, the audit's pattern checklist gains an
additional row at the bottom:

```
 +  Script hygiene                       <agg>     <letter>  <summary>
```

Where `<agg>` is the aggregate status:

- `✓` if every rule on every script is `ok`.
- `~` if any rule on any script is `warn` (and none `fail`).
- `✗` if any rule on any script is `fail`.

`<letter>`:

- `A` when `<agg>` is `✓`.
- `C` when `<agg>` is `~`.
- `F` when `<agg>` is `✗`.

`<summary>`: count of files vs. rules that fired non-`ok`, e.g.,
`2 files, 3 warnings, 0 failures`.

The script-hygiene row is **excluded from the weighted GPA** in the rubric.
It is reported as a sidebar finding because it is conditional on archetype
and presence of `scripts/`. The author can act on it independently of the
overall grade.

---

## Archetype awareness

| Archetype | scripts/ presence | This rule applies? |
|---|---|---|
| `orchestrator-with-subcommands` | optional | when present |
| `single-purpose-rigid`          | optional | when present |
| `single-purpose-flexible`       | optional | when present |
| `reference-only`                | discouraged | n/a — surface as a separate "reference-only with scripts" warning |
| `unknown`                       | optional | when present |

A `reference-only` skill that ships scripts is structurally inconsistent.
The audit surfaces this as a top-level note and recommends archetype
re-classification (or extracting the scripts into a sibling skill).

---

## Modernize integration

When `modernize` runs against a target whose audit produced any
`scriptHygiene` finding with `status: "fail"`, it adds these to the
modernize plan as `add-section` (manifest creation), `replace-section`
(error-handling injection), or annotation-only (secret-scan failures, which
require human judgment to fix and are surfaced but not auto-edited).

`modernize` never auto-edits to remove a suspected secret. The risk of
false positives is too high. Secret-scan `fail` is reported in the diff
preamble with a `MUST FIX MANUALLY BEFORE APPLY` banner; the user's gate
covers the acknowledgment but the edit itself is the user's responsibility.

---

## What this rule never does

- Never executes the scripts. Only static reads.
- Never quotes a matched secret in any output.
- Never auto-fixes a secret-scan failure.
- Never assumes a missing manifest is a `fail`. Comment-block declarations
  are an acceptable alternative.
- Never penalizes a `reference-only` archetype for not having `scripts/`.
- Never grows beyond the five rules above without a `refresh` cycle that
  documents the addition in this file's version history.
