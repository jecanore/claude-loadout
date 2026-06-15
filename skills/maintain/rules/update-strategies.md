# Update Strategies — Per-File-Type Handling

How to edit each file type when replacing stale references. The approach varies by file type because the consequences of a bad edit differ.

## Markdown Documentation

**Files:** `*.md` in docs, README, CONTRIBUTING, planning directories.

**Strategy: Section replacement.** Replace entire outdated sections rather than individual words. Line-by-line edits fragment the narrative and produce awkward prose.

**Process:**
1. Identify the section containing stale references (usually a paragraph or subsection)
2. Read the full section to understand its intent
3. Rewrite the section to describe the current system
4. Use the `Edit` tool with the old section as `old_string` and the new section as `new_string`

**Example:**
```
Old: "The application uses mock JSON files in `src/lib/mock/` for all property data.
     These files simulate the API responses that will eventually come from a database."

New: "The application queries Supabase PostgreSQL for property data. The data pipeline
     validates rows with Zod (`src/lib/validators/property.ts`) and maps them to
     frontend types (`src/lib/mappers/property.ts`)."
```

**Rules:**
- Preserve the document's existing tone and structure
- Don't add information unrelated to the migration
- Keep section length similar to the original
- Update any code examples or command references in the section
- If a section becomes irrelevant (e.g., "How to add mock data"), remove it entirely rather than leaving a stub

## Source Code Comments

**Files:** `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.py`, etc.

**Strategy: Comment-only edits.** Edit the text of comments. Never modify the surrounding code logic, even if it looks related.

**Process:**
1. Read the comment and the code it describes
2. Verify the code is actually using the new technology (if the code still uses the old technology, the comment is accurate — skip it)
3. Rewrite the comment to describe what the code actually does now
4. Remove stale TODOs that have been completed

**Example:**
```typescript
// Old comment:
// TODO: Replace with real database query
const properties = await fetchProperties(tenantId)

// New comment:
// Queries Supabase filtered by tenant
const properties = await fetchProperties(tenantId)
```

**Rules:**
- Only edit if the comment is inaccurate relative to the code it annotates
- Remove `TODO` comments for work that's been completed
- Don't add new comments — only update existing ones
- Don't touch `@ts-ignore`, `eslint-disable`, or other pragma comments
- Keep comment style consistent (single-line `//` vs block `/* */`)

## Test Files

**Files:** `*.spec.ts`, `*.test.ts`, `*.e2e.ts`, test fixtures, test utilities.

**Strategy: Flag and present options.** Test updates require design decisions. Don't auto-fix.

**Two approaches to present to the user:**

### Option A: Dynamic Queries
Replace hardcoded IDs/values with queries that fetch real data:
```typescript
// Before: hardcoded mock ID
const propertyId = 'test-item-001'

// After: query first available item
const { data } = await supabase.from('items').select('id').limit(1).single()
const propertyId = data.id
```

**Pros:** Tests verify real behavior. No fixture maintenance.
**Cons:** Tests depend on database state. Slower. May be flaky.

### Option B: Test Fixtures
Seed a test database with known data matching the old test expectations:
```typescript
// Before test suite
await seedTestData([
  { id: 'test-item-1', name: 'Test Item', tenant_id: 'test-tenant' }
])
```

**Pros:** Deterministic. Fast. Tests are self-contained.
**Cons:** Fixtures drift from real schema. Extra maintenance.

**Present both options** in the Step 3 plan and let the user decide per test file or test suite.

## Historical / Archived Documents

**Files:** `.context/`, changelogs, dated decision records, retrospective notes.

**Strategy: Disclaimer header only.** Never modify the body of a historical document.

**Process:**
1. Prepend a blockquote disclaimer at the top of the file
2. Leave all other content untouched

**Template:**
```markdown
> **Historical Note (YYYY-MM-DD):** This document was written when [old context].
> The system now uses [new_context]. Content below reflects the original state.
```

**Rules:**
- Use the current date (date of the update, not the document's original date)
- Describe both old and new in the disclaimer
- Don't modify, delete, or reorganize any content below the header
- If a disclaimer already exists, update it rather than adding a second one

## Configuration Files

**Files:** `tsconfig.json`, `eslint.config.*`, `vitest.config.ts`, `jest.config.*`, `package.json` scripts, CI workflows.

**Strategy: Flag for review.** Configuration changes can break builds. Don't auto-edit.

**Process:**
1. Identify the stale reference (e.g., a path in `tsconfig.json` pointing to deleted mock files)
2. Determine if it's a comment (safe to edit) or functional config (needs review)
3. For functional config: present the current value and proposed change, explain the impact
4. Wait for user approval

**Common patterns:**
- `tsconfig.json` paths pointing to removed directories → remove the path
- `package.json` scripts referencing deleted mock commands → remove or update the script
- CI workflow steps that run against mock data → update to use real database or test fixtures
- ESLint config ignoring mock directories → remove the ignore rule

## Mixed Files

Some files contain multiple types of content (e.g., a README with both current docs and a historical changelog section).

**Strategy:** Apply the most specific strategy to each section:
- Current documentation sections → Section replacement (Markdown strategy)
- Historical changelog entries → Disclaimer header only
- Embedded code examples → Update to reflect current API
- Command references → Verify commands exist and update

Process the file once with all changes, not multiple passes.
