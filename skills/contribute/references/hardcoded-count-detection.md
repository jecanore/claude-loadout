# Hardcoded Count Detection

Finds test assertions that break when you add or remove files. This is the most common CI failure in contributions that add new entities (agents, commands, plugins, etc.).

## When to Run

Only trigger when the diff ADDS or REMOVES files. File modifications alone don't affect count assertions.

```bash
# Get added/removed files
git diff --name-status upstream/<default>...HEAD | grep -E '^[AD]'
```

## Algorithm

### Step 1: Classify the Change

For each added/removed file, determine the entity type by directory:

| Directory pattern | Entity type |
|------------------|-------------|
| `agents/`, `agent/` | agent |
| `commands/`, `cmd/` | command |
| `plugins/`, `plugin/` | plugin |
| `workflows/`, `workflow/` | workflow |
| `templates/`, `template/` | template |
| `skills/`, `skill/` | skill |
| `middleware/`, `mw/` | middleware |
| `routes/`, `route/` | route |
| `models/`, `model/` | model |
| `migrations/` | migration |
| `tests/`, `test/`, `__tests__/` | test (skip — adding tests shouldn't break counts) |

Record: `{ entity_type, directory, files_added: N, files_removed: M }`

### Step 2: Find Test Files

Discover test directories:
```bash
# Common test locations
find . -type d -name "tests" -o -name "test" -o -name "__tests__" | head -20
# Test file patterns
find . -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" | head -50
```

For each entity type's directory, search test files for count-related patterns:

```bash
# Search for files that enumerate the entity directory
grep -rl "<entity_directory>" tests/ test/ __tests__/ 2>/dev/null

# Within those files, look for count patterns
grep -n "readdirSync\|readdir\|glob\|\.length\|assert\|expect\|strictEqual\|toBe\|toHaveLength" <matched_files>
```

### Step 3: Extract Count Assertions

Parse matched files for three patterns:

**Pattern A — `.length` with numeric literal in assertion:**
```javascript
// FLAGGED: hardcoded count
expect(agents.length).toBe(17);
assert.strictEqual(files.length, 23);
agents.should.have.length(17);

// NOT FLAGGED: dynamic count (both sides use .length)
expect(found.length).toBe(expected.length);
```

Detection: find `.length` followed within 5 tokens by a numeric literal inside an assertion call. Skip if `.length` appears on BOTH sides of the comparison.

**Pattern B — Explicit arrays of expected names:**
```javascript
// FLAGGED: hardcoded list
const expectedAgents = ['agent-a', 'agent-b', 'agent-c'];
expect(discovered).toEqual(expectedAgents);

// Also flagged:
expect(names).toEqual(['foo', 'bar', 'baz']);
```

Detection: array literal containing string elements, used in an assertion. Count the array elements.

**Pattern C — `readdirSync` near numeric assertion:**
```javascript
// FLAGGED: file count check
const files = readdirSync(agentsDir);
// ... up to 10 lines ...
expect(files.length).toBe(17);
```

Detection: `readdirSync` or `readdir` call within 10 lines of a numeric assertion.

**Pattern D — Filtered counts (medium confidence):**
```javascript
// FLAGGED with confidence: medium
const mdFiles = files.filter(f => f.endsWith('.md'));
expect(mdFiles.length).toBe(12);
```

Detection: `.filter(` within 5 lines of `.length` with numeric literal. Flag with `confidence: medium` because the filter may exclude the added file.

### Step 4: Validate

For each detected assertion, run the same enumeration to get the current count:

```bash
# Count actual files in the entity directory
ls -1 <entity_directory>/*.md 2>/dev/null | wc -l
# Or match the exact glob/filter pattern from the test
```

Compare: `current_count + files_added - files_removed != asserted_count` → FLAG

### Step 5: Report

Present results as a table:

```
## Hardcoded Count Assertions Found

| File | Line | Current Value | Expected After Change | Asserted Value | Fix |
|------|------|--------------|----------------------|----------------|-----|
| tests/copilot-install.test.cjs | 752 | 17 | 18 | 17 | Change `17` to `18` |
| tests/validate.test.js | 45 | ['a','b','c'] | ['a','b','c','d'] | ['a','b','c'] | Add 'd' to array |

Confidence: high (2), medium (0)
```

## Known Limitations

Document these clearly so users know what ISN'T covered:

- **Snapshot tests (`.snap`):** Not scanned. If the project uses Jest snapshots that include entity lists, manual review is needed. Run `npm test -- -u` to update snapshots after changes.
- **CI config thresholds:** Coverage percentages, timeout values, and other CI config numbers are excluded from scanning.
- **Python `len()` assertions:** Not supported in v1. Pattern: `assert len(items) == N`. Planned for v2 with pluggable language patterns.
- **Go table-driven tests:** Not supported. Would need AST parsing to detect `[]struct{...}` test tables.
- **Bash `wc -l` tests:** Not supported. Rare enough to not warrant detection.
- **Dynamically generated counts:** If the test reads a config file to determine expected count, it won't be flagged (correctly — it's not hardcoded).
- **Monorepo cross-package counts:** If a test in package A counts entities in package B, and you're adding to package B, the test in package A may not be in the obvious test directory.

## Edge Cases

- **Multiple entity types in one diff:** Run detection for each entity type independently.
- **Test file itself is added/removed:** Skip — adding a test shouldn't trigger count detection on other tests.
- **Count is 0 or 1:** Still flag. Even `expect(x.length).toBe(1)` breaks if you add a second entity.
- **Negative assertions:** `expect(x.length).not.toBe(0)` — skip, this isn't a count assertion.
