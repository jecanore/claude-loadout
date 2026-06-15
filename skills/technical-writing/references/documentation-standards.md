# Documentation Standards

Universal principles for effective documentation. Language-agnostic — focus on what and when to document.

## Core Principle

**Good code documents itself. Comments explain what code cannot.**

Prefer clear names and simple structure over comments. Write comments for reasoning, not restating.

## Comments vs Code

### When to Comment

**ALWAYS comment:**
- **Why** — reasoning, trade-offs, decisions
  - "Use exponential backoff to avoid overwhelming API during outages"
  - "Chose algorithm X over Y because of O(n) vs O(n2) performance"
- **Non-obvious decisions**
  - "Cache invalidation: 5 minutes chosen to balance freshness vs load"
  - "Intentionally skipping validation here — already validated upstream"
- **Workarounds**
  - "Temporary fix for bug in library X version 1.2.3"
  - "Work around browser quirk in Safari < 15"
- **Gotchas and constraints**
  - "Must call init() before use or will throw"
  - "Not thread-safe — caller must synchronize"
  - "Order matters: must authenticate before making requests"

**SOMETIMES comment:**
- **Complex algorithms** — high-level what, not line-by-line
  - "Binary search to find insertion point in sorted array"
- **Business rules**
  - "Tax calculation per regulation ABC-123 effective Jan 2024"

**RARELY comment:**
- **What** — code should be self-documenting. If you need to explain what, improve naming/structure first.

**NEVER comment:**
- Obvious code — `i++ // Increment i`
- Commented-out code — delete it, it's in git
- Lies — outdated comments are worse than no comments

### "Why Not What" Examples

Good (explains reasoning):
```
// Use exponential backoff to prevent thundering herd
retryDelay = baseDelay * Math.pow(2, attempt)

// Cache for performance — database query is expensive
const cachedResult = cache.get(key)
```

Bad (restates code):
```
// Set retry delay to base delay times 2 to the power of attempt
retryDelay = baseDelay * Math.pow(2, attempt)

// Get cached result from cache
const cachedResult = cache.get(key)
```

### Exceptions

Complex algorithms benefit from high-level "what":
```
// Find longest common subsequence using dynamic programming
// Returns length and the subsequence itself
function longestCommonSubsequence(s1, s2)
```

Public API contracts (inputs, outputs, errors):
```
// Authenticates user with email and password
// Returns: User object on success
// Throws: AuthError if credentials invalid
// Throws: NetworkError if connection fails
function authenticate(email, password)
```

### Comment Density

Prefer over comments:
1. Better names
2. Simpler code structure
3. Extracted functions (self-documenting)
4. Smaller modules

**Rule:** If you need a comment to explain what code does, refactor first.

## README.md Structure

Every project needs a README. Required sections:

### 1. What (one sentence)
Clear, concise description.
- "Task management CLI tool for developers"

### 2. Why (problem it solves)
- "Existing task managers don't integrate with git/editors"

### 3. Quick Start (fastest path to running)
- Installation + basic usage example
- This comes FIRST after description

### 4. Setup (getting started)
- Prerequisites, installation steps, configuration

### Optional sections (add as needed):
- Examples, Features, Documentation links, Contributing, License, Troubleshooting

### README Anti-Patterns
- Novel-length README — save details for separate files
- Out-of-date examples — worse than no examples
- No quick start — don't force users to read everything first
- Installation that doesn't work — test your own instructions

## Other Documentation Types

### ADRs (Architecture Decision Records)
- **When:** Making significant architectural choices
- **Format:** Context → Decision → Consequences
- **Example:** "Why we chose database X over Y"

### ARCHITECTURE.md
- **When:** System complex enough to need overview
- **Content:** Components, relationships, data flow
- **Keep:** Updated with major changes

### CONTRIBUTING.md
- **When:** Accepting external contributors
- **Content:** Setup, workflow, standards, review process

### CHANGELOG.md
- **When:** Project has releases/versions
- **Format:** Chronological, grouped by version
- **Sections:** Added, Changed, Fixed, Removed

### API Documentation
- **When:** Building libraries for others
- **Best:** Generated from code comments (stays in sync)
- **Avoid:** Manually maintained separate docs (get stale)

## Documentation Maintenance

### When to Update

**ALWAYS:** Breaking changes, new features, deprecated features
**USUALLY:** Bug fixes that change behavior, new config options
**RARELY:** Internal refactors, bug fixes that don't change behavior

### Stale Docs Are Worse Than No Docs

Users trust documentation. Wrong documentation wastes time and builds mistrust.

If you can't maintain docs:
- Delete them (better than lying)
- Or clearly mark as outdated
- Or link to code as source of truth

### Documentation Debt

**Defer when:** Experimental features, internal tools, prototypes
**Unacceptable when:** Feature ships to users, onboarding new team members, open sourcing

## Diagrams

**Use for:** System architecture, data flow, state machines, complex interactions
**Don't use:** As decoration, for simple systems, without maintaining them

Principles:
- Keep simple — complex diagrams become stale
- Text-based preferred — version control friendly, easy to update
- Maintain or delete — don't let diagrams lie

## Automated Quality Tools

- **Link checking:** lychee (`brew install lychee`) — checks all links in markdown
- **Style linting:** Vale (`brew install vale`) — enforces style guides
- **Freshness detection:** git-based age checks for stale docs

## Exit Codes and Error Codes

When documenting exit codes, error codes, or error-to-behavior mappings:
1. **Trace actual code paths** — document what the code does, not intent
2. **Check all callers** — an error code might be defined but never used
3. **Grep for the constant** — reveals actual usage
4. **Verify after writing** — check each documented code against its trigger in the codebase

## Quick Reference Checklist

**Before writing a comment:**
- [ ] Can I make the code clearer instead?
- [ ] Am I explaining "why" or just "what"?
- [ ] Would future me find this helpful?

**Before shipping a feature:**
- [ ] README updated (if user-facing)?
- [ ] Breaking changes documented?
- [ ] Examples still work?

**Starting new project:**
- [ ] README with What, Why, Quick Start, Setup
- [ ] License (if sharing)
- [ ] .gitignore

**Making architectural decision:**
- [ ] Should this be an ADR?
- [ ] Will team need context in 6 months?
