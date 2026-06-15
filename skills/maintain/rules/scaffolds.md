# Scaffold Rules

Convention detection and generic scaffold templates for any repository.

## Convention Detection

Run these checks before scaffolding to adapt templates to the project:

### 1. Source Directory
Check in order, use first found:
- `src/` — standard source directory
- `app/` — Next.js / Remix app directory
- `lib/` — library source
- `packages/` — monorepo packages

If none found, use repo root.

### 2. Package Manager
Detect by lock file:
- `bun.lock` or `bun.lockb` → bun
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `package-lock.json` or none → npm

### 3. Test Runner
Check `package.json` `devDependencies` for:
- `vitest` → Vitest (`npx vitest run`)
- `jest` → Jest (`npx jest`)
- `mocha` → Mocha (`npx mocha`)

Also check for config files: `vitest.config.*`, `jest.config.*`, `.mocharc.*`

If none found, check `scripts.test` in `package.json` for clues.

### 4. Language
- `tsconfig.json` exists → TypeScript
- Otherwise → JavaScript

### 5. Framework
Check `package.json` `dependencies` or `devDependencies` for:
- `next` → Next.js
- `nuxt` → Nuxt
- `@remix-run/node` or `@remix-run/react` → Remix
- `express` → Express
- `fastify` → Fastify
- `hono` → Hono
- `@angular/core` → Angular
- `vue` → Vue
- `svelte` or `@sveltejs/kit` → Svelte/SvelteKit

### 6. Build Command
Read `package.json` `scripts.build`. Common patterns:
- `tsc` → TypeScript compiler
- `next build` → Next.js
- `vite build` → Vite
- `esbuild` → esbuild

### 7. Monorepo Detection
- `workspaces` field in `package.json` → npm/yarn workspaces
- `pnpm-workspace.yaml` exists → pnpm workspaces
- `lerna.json` exists → Lerna
- `turbo.json` exists → Turborepo

## Scaffold Templates

All templates use detected conventions. Replace `{placeholders}` with detected values.

### Root CLAUDE.md

Only scaffold if no `CLAUDE.md` exists at repo root.

```markdown
# {project-name}

> {one-line description from package.json "description" field, or "TODO: add description"}

## Conventions

- {language} {with framework if detected}
- {package-manager} for dependency management
- {test-runner} for testing

## Build Commands

```bash
{package-manager} install    # Install dependencies
{scripts.build or "# no build script detected"}
{scripts.test or "# no test script detected"}
{scripts.dev or "# no dev script detected"}
```

## Key Files

| File | Purpose |
|------|---------|
| {detected source files — top 5 by size or importance} | |
```

### Child CLAUDE.md

Scaffold for source subdirectories with 3+ files that lack a CLAUDE.md.

```markdown
# {subdirectory-name}

## Gotchas

<!-- Add non-obvious behaviors, edge cases, or traps -->

## Key Files

| File | Purpose |
|------|---------|
| {list .ts/.js files in subdir} | |
```

### docs/spec/README.md

```markdown
# Specification Documents

| File | Scope | Last Updated |
|------|-------|--------------|
| <!-- Add spec files as they're created --> | | |
```

### .academy/README.md

Only scaffold for projects with 5+ source subdirectories.

```markdown
# Academy

Learning guides for this codebase.

## Guides

| Guide | Topic | Key Files |
|-------|-------|-----------|
| <!-- Add guides as they're created --> | | |
```

### CHANGELOG.md

See `rules/changelog.md` for the scaffold template.

### .gitnexus/

Don't scaffold files directly. Instead, check if `gitnexus` is available:
```bash
npx gitnexus --version 2>/dev/null
```

If available, run:
```bash
npx gitnexus analyze
```

If not available, inform the user: "GitNexus not installed. Install with `npm i -D gitnexus` to enable codebase indexing."

### MEMORY.md

```markdown
# {project-name} Memory

<!-- Memory entries are linked here as pointers. See ~/.claude/skills/maintain/SKILL.md for format. -->
```

## Scaffold Behavior Rules

1. **Never overwrite existing files** — only scaffold files that don't exist
2. **Detect before assuming** — run convention detection first, don't hardcode tools or paths
3. **Minimal content** — scaffolds are starting points, not complete documentation
4. **Ask before creating** — present the scaffold checklist and let the user select which artifacts to create
5. **One commit** — if multiple artifacts are scaffolded, offer a single commit: `docs: scaffold project documentation`
