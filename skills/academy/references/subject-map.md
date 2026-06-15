# Subject Map

Maps `/academy` subjects to their `.academy/` folders and lists example topics. This file is the source of truth for valid subjects.

## Adding a New Subject

If the user requests a subject not listed here, create the folder and add it to this table. Keep subjects broad — topics provide the specificity.

## Subjects

| Subject | Folder | Example Topics |
|---------|--------|---------------|
| basics | `basics/` | typescript-101, react-101, sql-101, reading-code, prompting-ai-agents |
| devops | `devops/` | ci-cd, docker, environments, deployment, monitoring, secrets-management |
| git | `git/` | branching, merging, rebasing, workflows, hooks, bisect |
| javascript | `javascript/` | async-await, closures, modules, promises, event-loop, error-handling |
| typescript | `typescript/` | generics, utility-types, strict-mode, type-guards, declaration-files |
| react-native | `react-native/` | navigation, accessibility, animations, native-modules, expo-router, nativewind |
| testing | `testing/` | jest-basics, mocking, integration-tests, snapshot-testing, test-patterns |
| architecture | `architecture/` | design-patterns, state-management, feature-modules, dependency-injection |
| databases | `databases/` | sql-basics, migrations, supabase, row-level-security, indexes, triggers |
| security | `security/` | auth-flows, secrets, otp, environment-variables, cors, csrf |
| networking | `networking/` | http, rest-apis, websockets, dns, ssl-tls, request-lifecycle |
| researchclaw | `researchclaw/` | getting-started, configuration, pipeline-stages, first-research, output-inspection, literature-system, experiments, multi-agent, troubleshooting |
| python | `python/` | dataclasses, enums, pathlib, subprocess, ast-parsing, yaml-config |
| scraping | `scraping/` | end-to-end-workflow, selenium-waits, extractor-pattern, anti-block-defenses, proxy-fallback, image-pipeline |
| workflow | `workflow/` | git-worktree-parallelization, atomic-commits, planning-phases, multi-claude-orchestration |

## File Naming Convention

Output files follow the pattern: `.academy/<subject>/<topic>-guide.md`

Examples:
- `/academy basics typescript-101` → `.academy/basics/typescript-101-guide.md`
- `/academy devops ci-cd` → `.academy/devops/ci-cd-guide.md`
- `/academy git branching` → `.academy/git/branching-guide.md`
- `/academy testing mocking` → `.academy/testing/mocking-guide.md`

## Codebase Relevance — Dynamic Discovery

When generating guides, discover relevant source files for each subject dynamically. Do not assume any specific directory structure.

1. **Read CLAUDE.md** for documented architecture, directory conventions, and feature module patterns.
2. **Search by subject:**

| Subject | Discovery Strategy |
|---------|-------------------|
| basics | Search broadly across the main source directory. For 101 guides, pull snippets from multiple areas. |
| devops | Look for `.github/`, CI configs, Dockerfiles, deployment configs, build scripts, git hook configs. |
| git | Check `.gitignore`, git hook configs, commit history, branching patterns via `git log`. |
| javascript | Search for `.js`/`.ts` files in the main source directory. Check for bundler configs. |
| typescript | Look for `tsconfig.json`, shared type directories, `*.d.ts` files, feature-level `types/` folders. |
| react-native | Search for `app/` directory, screen components, shared components, navigation configs, `app.json`/`app.config.*`. |
| testing | Look for test runner configs, `*.test.*`/`*.spec.*` files, `__tests__/` directories. |
| architecture | Examine top-level directory structure, feature module organization, shared utilities, layout/routing files. |
| databases | Search for `migrations/`, database client configs, ORM models, seed files, schema definitions. |
| security | Look for auth-related modules, `.env.example`, middleware, API route guards. |
| networking | Search for API client code, service layers, fetch/axios wrappers, WebSocket handlers. |

3. **If a subject has no matching files**, note this in the guide and use illustrative examples clearly marked as hypothetical.
