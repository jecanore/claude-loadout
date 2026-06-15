# Rule: lock-drift

Detection rules for lockfile drift. Loaded by [`/maintain locks`](../references/subcommands/locks.md).

## Lockfile Detection

Scan repo root and workspace roots (in monorepos) for these files. Multiple lockfiles are allowed only if they belong to different package managers in different workspaces.

| Manager | Manifest | Lockfile | Workspace marker |
|---|---|---|---|
| npm | `package.json` | `package-lock.json` | `package.json#workspaces` |
| yarn (1) | `package.json` | `yarn.lock` | `package.json#workspaces` |
| yarn (berry) | `package.json` + `.yarnrc.yml` | `yarn.lock` | `package.json#workspaces` |
| pnpm | `package.json` + `pnpm-workspace.yaml` | `pnpm-lock.yaml` | `pnpm-workspace.yaml` |
| bun | `package.json` | `bun.lockb` | `package.json#workspaces` |
| pip | `requirements.txt` | `requirements.lock` (uv) or pinned `requirements.txt` | — |
| poetry | `pyproject.toml` | `poetry.lock` | — |
| uv | `pyproject.toml` | `uv.lock` | — |
| cargo | `Cargo.toml` + optional `[workspace]` | `Cargo.lock` | `[workspace]` table |
| go | `go.mod` (+ `go.work` for workspaces) | `go.sum` | `go.work` |
| composer | `composer.json` | `composer.lock` | — |
| bundler | `Gemfile` | `Gemfile.lock` | — |

## Drift Categories

### `manifest-mismatch`

Manifest declares a version range (e.g., `"zod": "^3.22.0"`), but the lockfile pins a version that no longer satisfies it (e.g., manifest changed to `^4.0.0` but lockfile still pins `3.22.4`).

**Detection:**
- Parse manifest dependencies + devDependencies + peerDependencies.
- Parse lockfile resolutions for each dependency.
- For each dependency: assert lockfile version satisfies manifest range using semver.
- For pip/poetry/uv: compare manifest constraint to lockfile pinned version.

**Recommended:** `<pm> install` (the user runs it).

### `integrity-fail`

Lockfile-recorded checksums don't match what's installed in `node_modules` (or equivalent).

**Detection:**
- For pnpm: parse `pnpm-lock.yaml` integrity hashes; spot-check against `node_modules/.pnpm` if present.
- For npm: parse `package-lock.json` integrity SRI hashes; compare to current.
- For yarn berry: parse `.yarn/cache/*.zip` checksums.

This check is conservative — only flag if `node_modules` exists and clearly drifted.

**Recommended:** `<pm> install --frozen-lockfile` to confirm; if it fails, the lockfile is the source of truth and `node_modules` is stale.

### `dual-lockfile`

Two lockfiles for different package managers in the same workspace.

**Detection:**
- For each workspace: count distinct lockfiles. If > 1, classify as `dual-lockfile`.
- Subtle case: `pnpm-workspace.yaml` at root + `package-lock.json` at root → npm one is stale (pnpm wins).

**Recommended:** confirm primary, remove the stale lockfile (manually after user verification).

### `stale-resolution`

Lockfile predates manifest by N commits (default 10). Often a sign that someone edited manifest by hand without running `install`.

**Detection:**
```bash
git log --oneline -n <N> -- <manifest> | wc -l   # commits touching manifest in last N
git log --oneline -1 --format=%H -- <lockfile>   # last commit touching lockfile
```

If lockfile's last commit is older than the latest manifest-touching commit, flag.

**Recommended:** `<pm> install` to refresh lockfile.

### `peer-dep-drift`

Manifest declares peer dependencies that aren't satisfied by what's installed.

**Detection:**
- Parse `peerDependencies` and `peerDependenciesMeta` from manifest.
- For each: check the installed version (from lockfile resolution) against the peer range.
- Flag missing peers (unless `peerDependenciesMeta[X].optional === true`).

**Recommended:** install missing peer; or update manifest to drop the requirement; manual judgment.

## Monorepo Considerations

| Pattern | Behavior |
|---|---|
| `pnpm-workspace.yaml` at root | pnpm is primary. Per-package lockfiles inside workspaces are unexpected; flag. |
| `npm` workspaces | Single root lockfile. Per-workspace lockfiles flagged as `dual-lockfile`. |
| `yarn` workspaces | Single root lockfile. |
| `bun` workspaces | Single root lockfile. |
| `cargo` workspace | Single root `Cargo.lock`. |
| `go work` | Per-module `go.sum`; `go.work.sum` for workspace-wide. Both can coexist. |

## Output

Each finding records:

```ts
{
  workspace: string;          // 'apps/web' | '.'
  lockfile: string;
  manifest: string;
  issue: 'manifest-mismatch' | 'integrity-fail' | 'dual-lockfile' | 'stale-resolution' | 'peer-dep-drift';
  detail: string;
  suggested: string;          // shell command to fix (NOT auto-run)
}
```

## Never

- Run `npm install`, `pnpm install`, `yarn install`, `bun install`, `cargo update`, `pip install`, etc. The user runs these.
- Delete a lockfile.
- Edit `node_modules`.
