# Subcommand: `locks` (new 2026-05)

Detect lockfile drift across supported package managers. Surface for user decision; never auto-fix.

## TodoWrite Items

```
- [ ] Detect all lockfiles in repo (single or monorepo)
- [ ] If none, surface skip; STOP
- [ ] Determine primary package manager (workspace config wins)
- [ ] For each manifest/lockfile pair, run drift checks
- [ ] Aggregate findings into state.lockDrift
- [ ] Present drift report with recommended commands (never run automatically)
- [ ] If `full` invocation: surface as warnings, do not block other steps
```

## Drift Checks

Load `rules/lock-drift.md`. For each lockfile:

| Issue | Detection | Action |
|---|---|---|
| `manifest-mismatch` | manifest version range cannot resolve to lockfile-pinned version | flag; suggest `<pm> install` |
| `integrity-fail` | manifest checksums (if recorded) don't match lockfile | flag; suggest `<pm> install --frozen-lockfile` to confirm |
| `dual-lockfile` | two lockfiles for different package managers in same workspace | flag; let user decide which to remove |
| `stale-resolution` | lockfile predates manifest by N commits (default 10) | warn; suggest refresh |
| `peer-dep-drift` | peer dependency declared but not satisfied | flag; suggest manual review |

## Supported Package Managers

| Manager | Manifest | Lockfile |
|---|---|---|
| npm | package.json | package-lock.json |
| yarn | package.json | yarn.lock |
| pnpm | package.json + pnpm-workspace.yaml | pnpm-lock.yaml |
| bun | package.json | bun.lockb |
| pip | requirements.txt / pyproject.toml | requirements.lock / poetry.lock |
| poetry | pyproject.toml | poetry.lock |
| cargo | Cargo.toml | Cargo.lock |
| go | go.mod | go.sum |
| composer | composer.json | composer.lock |
| bundler | Gemfile | Gemfile.lock |

## Monorepo Behavior

- `pnpm-workspace.yaml` present → pnpm is primary; flag any `package-lock.json` or `yarn.lock` as `dual-lockfile`.
- Per-workspace lockfiles in npm workspaces are unusual; flag as `dual-lockfile`.
- Mixed-language monorepos: run drift checks per workspace using its native package manager.

## Type label

**Rigid** for detection (correctness matters; false negatives ship broken installs).
**Never auto-fix** — `pnpm install`, `npm install`, etc. can mutate state irreversibly. Always surface and recommend; let the user run.

## Output Format

```
Lockfile drift report:

✗ apps/web/package.json vs apps/web/pnpm-lock.yaml
   manifest-mismatch: zod ^3.22.0 cannot resolve to pinned 3.20.1
   suggested: pnpm install --filter apps/web

⚠ apps/api/package-lock.json
   dual-lockfile: pnpm-workspace.yaml exists; this lockfile is from old npm migration
   suggested: rm apps/api/package-lock.json (after confirming pnpm covers this workspace)

✓ services/worker/Cargo.lock — no drift
```

## Quality Gate

PASS:
- All lockfiles consistent with manifests.
- No dual-lockfiles.
- Peer dependencies satisfied (or flagged-and-acknowledged by user).

FAIL:
- Any drift unresolved AND user has not explicitly acknowledged.

Recovery: drift findings remain in `state.lockDrift`; user runs install commands manually; re-run `locks` to verify.
