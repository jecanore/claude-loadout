# Discovery Patterns — Common Migrations

Grep patterns for common technology migrations, regex tips, and false positive avoidance.

## Common Migration Patterns

### Mock Data to Real Database

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `mock` | General mock references | "uses mock data" |
| `src/lib/mock` | Import paths to mock modules | `import { data } from 'src/lib/mock'` |
| `uses mock data` | Documentation statements | "The API uses mock data" |
| `all data.*mocked` | Broad statements about mocking | "all data is currently mocked" |
| `mock.*json` | Mock JSON file references | "reads from mock.json" |
| `test-item-\d+` | Hardcoded mock IDs | `test-item-0` |

**New context example:** `PostgreSQL via ORM/client`

### REST to GraphQL

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `fetch\(.*\/api` | Fetch calls to REST endpoints | `fetch('/api/users')` |
| `REST API` | Documentation references | "calls the REST API" |
| `endpoint` | Endpoint references in docs | "POST endpoint at /api/v1" |
| `/api/v[0-9]` | Versioned API paths | `/api/v1/properties` |
| `axios` | HTTP client imports | `import axios from 'axios'` |

**New context example:** `GraphQL via Apollo Client, queries in src/graphql/`

### Jest to Vitest

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `jest` | General Jest references | "configured with jest" |
| `jest\.mock` | Jest mock calls | `jest.mock('./module')` |
| `jest\.fn` | Jest function mocks | `const fn = jest.fn()` |
| `jest\.config` | Config file references | "see jest.config.js" |
| `@jest` | Jest packages | `@jest/globals` |
| `describe.*jest` | Jest in test descriptions | Not common but catches meta-tests |

**New context example:** `Vitest with vi.mock/vi.fn, config in vitest.config.ts`

### CommonJS to ESM

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `require\(` | CommonJS require calls | `const fs = require('fs')` |
| `module\.exports` | CommonJS exports | `module.exports = config` |
| `__dirname` | Node CJS globals | `path.join(__dirname, 'file')` |
| `__filename` | Node CJS globals | `console.log(__filename)` |
| `\.cjs` | CJS file references | "rename to .cjs" |

**New context example:** `ES modules with import/export, import.meta.url for paths`

### Class Components to Hooks

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `this\.state` | Class state access | `this.state.count` |
| `this\.props` | Class props access | `this.props.name` |
| `componentDidMount` | Lifecycle methods | `componentDidMount() {` |
| `componentWillUnmount` | Lifecycle methods | `componentWillUnmount() {` |
| `extends Component` | Class declarations | `class App extends Component` |
| `extends React\.Component` | Full class declarations | `extends React.Component` |

**New context example:** `Function components with useState, useEffect, custom hooks`

### CSS-in-JS to Tailwind

| Old Pattern | Catches | Example Match |
|-------------|---------|---------------|
| `styled\.` | styled-components | `styled.div` |
| `css\`` | Template literal CSS | ``css`color: red` `` |
| `makeStyles` | Material-UI styles | `const useStyles = makeStyles()` |
| `@emotion` | Emotion imports | `import styled from '@emotion'` |
| `\.module\.css` | CSS modules (if migrating away) | `import styles from './App.module.css'` |

**New context example:** `Tailwind CSS utility classes, cn() for conditional classes`

## Regex Tips for Grep Tool

### Case sensitivity
Most patterns should be case-insensitive. Use the `-i` flag on the Grep tool:
```
pattern: "mock data"
-i: true
```

### Word boundaries
To avoid matching "mock" inside "mockup" or "hammock":
```
pattern: "\bmock\b"
```
Note: `\b` works in ripgrep regex mode. For the Grep tool, this is the default.

### Multi-word patterns
Use `.*` for flexible spacing between words:
```
pattern: "all data.*mocked"    # matches "all data is currently mocked"
pattern: "uses.*mock.*data"    # matches "uses mock JSON data"
```

### OR patterns
Combine patterns with `|` in a single grep:
```
pattern: "mock|src/lib/mock|mocked"
```
This is more efficient than running three separate grep calls. Use separate calls only when you need different context or line counts per pattern.

### Escaping
Literal dots, parentheses, and brackets need escaping:
```
pattern: "jest\.mock"     # matches jest.mock, not jestXmock
pattern: "require\("      # matches require(
```

## False Positive Avoidance

### "mock" in non-technical context
The word "mock" appears in:
- "mockup" / "mock-up" — UI design context (not stale)
- "mock trial" — legal context (not stale)
- Variable names like `mockUser` in test fixtures — may be intentional

**Strategy:** After initial grep, scan results for false positives. Filter using file type — `mock` in a `.md` file is likely stale documentation, while `mock` in a `.test.ts` file may be an intentional test mock.

### "endpoint" in generic context
The word "endpoint" appears in legitimate current usage even after a REST-to-GraphQL migration (GraphQL has endpoints too).

**Strategy:** Look for patterns combining "endpoint" with REST-specific language: `REST endpoint`, `POST endpoint`, `/api/v1 endpoint`.

### Import paths that still exist
A grep for `src/lib/mock` might match files that legitimately still import from mock modules (e.g., mock auth that hasn't been migrated yet).

**Strategy:** Cross-reference grep results with the filesystem. If the imported file still exists and is in active use, the reference is not stale — it's a different migration task.

### Comments describing history
A comment like `// Migrated from mock data to Supabase in Jan 2026` contains "mock" but is not stale — it's accurate historical context.

**Strategy:** Read the full line context. If the match describes a past state using past tense ("was mocked", "migrated from mock"), it may be accurate history. If it describes current state using present tense ("is mocked", "uses mock data"), it's stale.

## Auto-Derived Discovery Sources

Used by `refs` Mode B (discovery). When the caller does not supply `old_patterns`, candidates are auto-derived from three independent sources, then merged, deduplicated, and confidence-scored before presentation.

The three sources are:

### Source 1 — Git rename/delete history

**Goal:** find symbols/files that were renamed or deleted recently. Their old names are likely candidates for stale references in docs and comments.

**Command:**
```
git log -p --diff-filter=DR --since=<since-ref> -- ':(exclude)<exclude-globs>'
```

`<since-ref>` defaults to the last release tag if one exists (`git describe --tags --abbrev=0`), otherwise `HEAD~30`. Override with `--since=<ref>`.

**Extraction:** parse the diff to extract:
- Deleted file paths (from `diff --git a/<path> b/<path>` followed by `deleted file mode`).
- Renamed file paths (from `rename from <old>` / `rename to <new>`).
- Symbol names removed from non-deleted files (lines starting with `-` that match an identifier-shaped token, scoped to declarations: `function`, `class`, `def`, `const`, `export`, `type`, `interface`).

**Confidence:**
- HIGH — file or symbol referenced in a Tier 1 doc (CLAUDE.md, .cursorrules, copilot-instructions.md).
- MEDIUM — referenced in a Tier 2 or 3 doc.
- LOW — only appears in source comments or test files.

**Caveat:** rename refactors that did not touch the deleted-symbol's text (e.g., reordering exports) appear as deletions. Cross-check against the new file to confirm the symbol no longer exists anywhere in the repo.

### Source 2 — AI context file claims vs current source

**Goal:** find symbols mentioned in AI-injected context files (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `README.md`) that no longer exist in source. These are the highest-impact stale references because they mis-train every future agent session.

**Process:**
1. Extract identifier-shaped tokens from the AI context files. Match `[A-Z][a-zA-Z0-9_]{2,}` and lowercase camelCase tokens that appear in code-context (inside backticks, after `function`/`class`/`hook`/`component`, in import paths).
2. For each token, run `Grep` over `<scope>` excluding the AI context files themselves.
3. Tokens with zero source hits are candidates.
4. Filter out:
   - Common English words and config keys (maintain a small ignore-list: `error`, `event`, `request`, `response`, `config`, `data`, `state`, etc.).
   - Tokens that appear in `package.json`/`tsconfig.json` (likely dependency names, not internal symbols).
   - Tokens inside fenced code blocks marked as `bash` or `shell` (likely command names, handle separately).

**Confidence:**
- HIGH — token appears 3+ times in AI context files and zero times in source.
- MEDIUM — token appears once in AI context files and zero times in source.
- LOW — token appears in source under a different casing or as a substring (possible rename rather than deletion).

**Caveat:** legitimate external-API names will appear in docs but not in source (e.g., `Stripe.PaymentIntent` referenced in onboarding docs without being imported anywhere). The user gates these out at the proposal screen — never auto-prune them, since the absence of a source hit can equally mean "stale" or "external".

### Source 3 — Repo watchlist

**Goal:** honor the repo owner's curated forbidden-pattern list.

**Source file:** `.claude/stale-watchlist.md` (format defined in `rules/stale-watchlist.md`).

**Process:** parse the watchlist's `## Forbidden literal strings` and `## Forbidden regex patterns` sections. Each pattern enters the candidate set with the watchlist's stated reason as the rationale.

**Confidence:** always HIGH — the repo owner has explicitly flagged these as regressions. The user still gates them at the proposal screen (a watchlist hit can be a legitimate exception in a specific file), but they are presented before MEDIUM/LOW candidates from other sources.

**Caveat:** if the watchlist file is missing, this source is a silent no-op — do not warn. The watchlist is opt-in.

## Merging the three sources

After all three sources run (in parallel where the tooling allows):

1. **Deduplicate** by (pattern, file:line) tuples. The same symbol surfaced by both git history and an AI-context-file scan is one candidate, not two — keep the highest confidence and concatenate the evidence.
2. **Sort** by confidence (HIGH → MEDIUM → LOW), then by Tier 1 file overlap (candidates that appear in CLAUDE.md or .cursorrules float to the top within their confidence band).
3. **Batch** in groups of ≤ 25 for the proposal screen. The caller can request "show next batch" rather than seeing a single 100-row dump.

## Anti-patterns specific to discovery mode

- **Don't auto-derive `new_context`.** The skill cannot reliably infer what replaced a deleted symbol. Surface the deletion, ask the user what to call it now.
- **Don't expand `<since-ref>` automatically when the empty-state triggers.** Empty-state means "no candidates found in the requested window" — that's a real result. Re-running with a larger window is a user decision.
- **Don't combine candidates from different migrations into a single sweep.** If discovery surfaces both a Jest→Vitest rename and a REST→GraphQL rename, present them as two separate sweep proposals — they have different `new_context` values and different priority-tier weightings.
