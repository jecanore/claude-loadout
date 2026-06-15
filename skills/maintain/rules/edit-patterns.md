# Edit Patterns

## Markdown Table Row Insertion

### Adding a row to an existing table

1. Identify the table boundaries (header row, separator row, data rows)
2. Find the correct insertion position:
   - For env vars: alphabetical by variable name, or grouped by feature
   - For dependencies: alphabetical by package name
   - For phases: by phase number
3. Match column alignment with existing rows
4. Use the Edit tool with `old_string` = last row before insertion + next row, `new_string` = last row + new row + next row

Example — adding an env var row:
```
old_string: | `LOG_LEVEL` | No | `info` | ... |
new_string: | `LOG_LEVEL` | No | `info` | ... |
| `THINKING_BUDGET_TOKENS` | No | `10000` | Max thinking tokens per request |
```

### Preserving table alignment

- Count the max width of each column from existing rows
- Pad new cell values with spaces to match
- If existing table uses no padding, don't add any

## Numeric Count Updates

Find the old count in prose and replace with new:
```
old_string: **31 tests passing**
new_string: **46 tests passing**
```

Or in a table cell:
```
old_string: | M2 | Test coverage | All | 31 tests (Phase 1) |
new_string: | M2 | Test coverage | All | 46 tests (Phase 1-2) |
```

## Status Marker Updates

```
old_string: | 2 | LLM + Block Streaming | Planned |
new_string: | 2 | LLM + Block Streaming | **DONE** |
```

## File Structure Tree Updates

Insert new entries maintaining the tree drawing characters:
```
old_string: │   ├── llm/
│   │   └── anthropic.ts
new_string: │   ├── llm/
│   │   ├── anthropic.ts
│   │   └── thinking.ts
```

Note: When adding entries, the previous last item's `└──` becomes `├──` and the new item gets `└──`.

## MEMORY.md Entry Patterns

Match the existing format. Common patterns:

**Key-value bullet:**
```
- **field name:** description of the field or pattern
```

**Plain bullet under heading:**
```
## Section Name
- New observation or pattern
```

**Nested context:**
```
## Module Notes
- `src/module/file.ts` — brief description of what it does
- New parameter: `paramName` on `functionName` — what it controls
```

Insert new entries at the end of the relevant section, before the next `##` heading.

## .env.example Entry Patterns

Add new variables with descriptive comments, grouped near related vars:
```
# Maximum thinking tokens for extended thinking mode
# Optional, defaults to 10000
THINKING_BUDGET_TOKENS=10000
```

Find the right insertion point by scanning for related variable names or section comments.

## CHANGELOG.md Entry Patterns

See `rules/changelog.md` for CHANGELOG-specific patterns. Entries go under `## [Unreleased]` in the appropriate category.

## General Rules

1. **Preserve existing formatting**: Match indentation, spacing, and style of surrounding content
2. **Minimal edits**: Change only what's needed. Don't reformat adjacent content
3. **Use Edit tool**: Always use the Edit tool for modifications. Never rewrite entire files
4. **Prose rewrites**: If rewriting a paragraph, reference `/technical-writing` skill when available for tone and clarity guidance
5. **No orphan references**: If adding a reference to something, ensure the target exists
6. **Quote accuracy**: When docs quote code (function names, variable names), use exact casing from source
