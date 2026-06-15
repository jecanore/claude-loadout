# Gap Analysis Rules

## Classification

For each (change, target_section) pair, classify as:

### GAP — Missing from docs
The change introduced something new that has no representation in the target section.

Examples:
- New env var `THINKING_BUDGET_TOKENS` not in the env var table
- New file `src/llm/thinking.ts` not in the file structure tree
- New dependency `@anthropic-ai/sdk` not in the dependencies table
- New phase completed but phase table still shows "Planned"

### STALE — Docs show old value
The docs reference something that the code has changed.

Examples:
- Docs say "31 tests passing" but diff added 15 new tests
- Docs say rate limit is "10 chat/min" but code changed to 15
- Docs show old function signature without new parameter
- Phase table shows "Planned" for a phase that's now complete

### OK — Already in sync
The docs already reflect the change. No action needed.

## Comparison Techniques

### Table Row Lookup
Search the table for the exact identifier (env var name, dependency name, etc.):
1. Split table into rows by `|` delimiter
2. Check if the identifier appears in any row (case-sensitive for env vars, case-insensitive for descriptions)
3. If found, compare the value/description columns against the change data
4. If not found, classify as GAP

### Numeric Count Extraction
Find numbers in prose text that represent counts:
```
"31 tests passing"      → extract 31
"10 chat/min"           → extract 10
"MAX_CONNECTIONS=100"   → extract 100
```
Compare extracted number against actual value from code/test output.

### Status Marker Detection
Look for status indicators in tables and lists:
```
| Phase 2 | ... | Planned |     → status is "Planned"
| Phase 2 | ... | **DONE** |    → status is "DONE"
| Phase 2 | ... | COMPLETE |    → status is "COMPLETE"
- [x] Feature X                 → completed
- [ ] Feature Y                 → not completed
```

### File Structure Comparison
Parse code block trees and check if new paths appear:
```
├── src/
│   ├── llm/
│   │   ├── anthropic.ts        ← exists in tree?
│   │   └── thinking.ts         ← new file, not in tree → GAP
```

### Fuzzy Name Matching
Config field names may differ between code and docs:
- Code: `thinkingBudgetTokens` (camelCase)
- Env: `THINKING_BUDGET_TOKENS` (SCREAMING_SNAKE)
- Docs: may use either form

Convert both to a normalized form (lowercase, no separators) before comparing:
- `thinkingbudgettokens` matches `thinkingbudgettokens`

## Output Format

Produce a gap report:
```
GAP  | CLAUDE.md | "Environment Variables (Current)" table | Missing THINKING_BUDGET_TOKENS row
GAP  | CLAUDE.md | "Environment Variables (Current)" table | Missing THINKING_MAX_TOKENS row
STALE | CLAUDE.md | "What's Already Built" | Says "31 tests" but actual count is 46
OK   | .env.example | — | THINKING_BUDGET_TOKENS already present
```

## Edge Cases

- **Section doesn't exist**: If the target section heading is missing from the doc, report as GAP with note "section missing — may need manual creation"
- **Multiple tables under one heading**: Match by column headers, not just heading proximity
- **Inline code references**: Check for backtick-wrapped references like `\`THINKING_BUDGET_TOKENS\`` in prose
- **Commented-out entries**: Treat `<!-- THINKING_BUDGET_TOKENS -->` or `# THINKING_BUDGET_TOKENS` as not present
