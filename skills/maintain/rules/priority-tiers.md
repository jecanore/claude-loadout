# Priority Tiers — Detailed Classification

How to categorize files discovered with stale references, why each tier matters, and how to handle edge cases.

## Tier Definitions

### Tier 1: CRITICAL — AI Context Files

**Files:** `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.agentrules`, any file that AI coding agents read on every session.

**Rationale:** AI context files are injected into every agent session. One stale line produces wrong code in every subsequent interaction. A `CLAUDE.md` that says "all data is mocked" causes the agent to generate mock-based code even after a real database exists. This is a **correctness multiplier** — every downstream session inherits the mistake.

**Action:** Edit immediately. Replace stale statements with accurate descriptions of the current system. Be precise — these files guide code generation.

### Tier 2: HIGH — Developer Onboarding

**Files:** `README.md`, `CONTRIBUTING.md`, `SETUP.md`, `docs/getting-started.md`, any top-level docs a new developer reads first.

**Rationale:** README is the first file new developers read. Stale setup instructions waste onboarding time and erode trust in documentation quality. If a README says "run `npm run mock:seed`" but that script no longer exists, the developer's first experience is a broken workflow.

**Action:** Edit to reflect current setup steps, prerequisites, and architecture. Verify all commands and paths are accurate.

### Tier 3: HIGH — Architecture & Planning Docs

**Files:** `.planning/`, `ARCHITECTURE.md`, `STRUCTURE.md`, `CONCERNS.md`, `INTEGRATIONS.md`, `ADR/`, design documents.

**Rationale:** Architecture docs guide design decisions. Wrong architectural context leads to wrong design. If a planning doc says "data layer: mock JSON files" when the system uses PostgreSQL, contributors may design features assuming no database exists.

**Action:** Edit architectural descriptions to match the current system. Update diagrams, data flow descriptions, and technology references.

### Tier 4: MEDIUM — Source Code Comments

**Files:** `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.py`, `*.go` — specifically the comment text, not the code logic.

**Rationale:** Source code comments mislead during debugging but don't affect runtime. A comment saying `// TODO: replace mock data` above a real database query is confusing but not harmful. Lower urgency than docs because comments have narrower reach (only seen when reading that specific file).

**Action:** Edit the comment text only. Do not modify surrounding code logic. Remove stale TODOs. Update descriptions of what the code does.

### Tier 5: LOW — Test Files

**Files:** `*.spec.ts`, `*.test.ts`, `*.e2e.ts`, `*.spec.tsx`, `__tests__/`, `cypress/`, `playwright/`.

**Rationale:** Tests with hardcoded old IDs or patterns fail but are caught by CI. The failure is loud and self-documenting. Fixing tests often requires design decisions (query real DB? use fixtures? mock differently?) that the user should weigh in on.

**Action:** Flag for the user. Present two strategies: (a) update hardcoded values to query dynamically, (b) seed a test database with known fixtures. Let the user decide.

### Tier 6: LOW — Historical / Archived Docs

**Files:** `.context/`, changelogs, `CHANGELOG.md`, archived decision records, dated planning docs, retrospective notes.

**Rationale:** Historical docs are time-stamped snapshots. They describe what was true at a point in time. Rewriting history removes valuable context about past decisions. The correct approach is to mark them as historical, not to update their content.

**Action:** Prepend a disclaimer header. Do not modify the document body:

```markdown
> **Historical Note (YYYY-MM-DD):** This document was written when [old context].
> The system now uses [new_context]. Content below reflects the original state.
```

## Edge Cases

### File spans two tiers

A file may match multiple tiers. Use the **highest applicable tier**.

Examples:
- `README.md` contains both onboarding instructions (Tier 2) and a historical changelog section (Tier 6). Apply Tier 2 — edit the onboarding sections, add a disclaimer header to the changelog section.
- A `.ts` file has both stale comments (Tier 4) and stale test helpers (Tier 5). Apply Tier 4 for comments, flag the test helpers separately.

### File is both current and historical

Some planning docs describe both the current architecture and the history of how it evolved. Edit the "current state" sections (Tier 3). Add disclaimer headers to "decision history" sections (Tier 6).

### Stale reference is intentional

The old technology may still exist in part of the system. For example, mock auth may persist after a database migration.

When a stale reference is **accurate** (the system still uses mocks for auth), leave it. In the final report, list it under "Remaining references" with justification: `"mock auth is still mock-based — intentional, not stale"`.

### Config files

Config files (`tsconfig.json`, `.eslintrc`, `jest.config.js`, `vitest.config.ts`) that reference old paths or plugins fall under **Tier 4** if they're comments, or require separate investigation if they're functional configuration. Flag functional config changes for user review — changing a build config can break the build.

## Migration Example

A typical mock-to-database migration produces tier assignments like:

| Tier | File | What Changed |
|------|------|-------------|
| 1 | `CLAUDE.md` | Removed "all data is currently mocked", added database pipeline docs |
| 2 | `README.md` | Updated setup instructions to include database initialization |
| 3 | `.planning/ARCHITECTURE.md` | Updated data layer from "mock JSON" to "PostgreSQL" |
| 3 | `.planning/CONCERNS.md` | Updated data concerns to reference real database |
| 4 | `src/hooks/useData.ts` | Updated comment about data source |
| 5 | `e2e/*.spec.ts` (5 files) | Flagged — still use hardcoded test IDs |
| 6 | `.context/*.md` | Added historical disclaimer headers |
