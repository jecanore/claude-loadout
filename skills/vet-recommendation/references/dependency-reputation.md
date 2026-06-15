<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Dependency Reputation

Load this file when the quick scan flags reputation concerns: low stars, single author, no recent activity, or unknown package.

## Verification Workflow

1. **GitHub stats** — Use `gh api repos/OWNER/REPO` or `mcp__github__get_file_contents` to get:
   - Stars, forks, watchers
   - `pushed_at` (last commit date)
   - `open_issues_count`
   - `archived` flag
   - License (`license.spdx_id`)
2. **Contributors** — `gh api repos/OWNER/REPO/contributors?per_page=5` → count unique authors, check if > 1 person has significant commits
3. **Package registry (npm API)** — `GET https://api.npmjs.org/downloads/point/last-month/PACKAGE` → returns `{ downloads: N }` for last-month download count. For other ecosystems, check PyPI JSON API or crates.io API.
4. **Alternatives search** — Web search `"[tool purpose] alternative site:github.com"` to find established competitors
5. **Transitive risk (deps.dev)** — `GET https://api.deps.dev/v3/systems/npm/packages/PACKAGE` → check dependency count, known advisories in transitive deps, and OpenSSF Scorecard score if available. High transitive dependency count increases supply chain attack surface.
6. **First-party check** — Before recommending a third-party tool, search if the platform/framework has a built-in or official solution

## Severity: CRITICAL

- **Typosquatting**: Package name is 1-2 characters different from a popular package (e.g., `lodsah` vs `lodash`). Verify exact name against the official registry.
- **Malicious indicators**: README asks to disable security features, run with `--no-verify`, or pipe curl to bash from untrusted source.

## Severity: HIGH

- **Single author + low adoption**: Only 1 contributor AND < 50 stars AND < 1000 weekly downloads. Bus factor of 1 with no community validation.
- **Abandoned**: No commits in 12+ months AND has open security issues or unmerged PRs from multiple contributors.
- **Archived repository**: `archived: true` — no further maintenance will occur.
- **First-party alternative exists**: A well-maintained official solution exists but wasn't considered.

## Severity: MEDIUM

- **Low adoption**: 50-500 stars, moderate downloads, but active development. Usable but less battle-tested.
- **Infrequent updates**: Last commit 6-12 months ago, but no open security issues. May be "done" rather than abandoned.
- **Single author, high adoption**: One maintainer but strong download/star count. Bus factor concern but community-validated.

## Severity: LOW

- **New but active**: < 6 months old, few stars, but active commits and responsive maintainer. Too early to judge.
- **Niche tool**: Low stars expected for the domain. Check if it's the only option in its niche.

## Longevity & Trajectory

Beyond current snapshot stats, assess whether the project is growing, stable, or declining:

1. **Stars trend** — Check star-history.com for visual trajectory, or query GitHub events API for recent starring activity. A flat or declining star curve on an actively marketed tool signals waning interest.
2. **Contributor activity (last 90 days)** — `gh api repos/OWNER/REPO/stats/contributors` → check if multiple contributors have commits in the last 90 days. A project with 50 contributors but only 1 active in the last quarter is effectively single-maintainer.
3. **Release cadence** — `gh api repos/OWNER/REPO/releases?per_page=5` → check dates between releases. Consistent cadence (monthly, quarterly) signals healthy governance. No releases in 12+ months with active commits may indicate stalled release process.
4. **Breaking change frequency** — Count major version bumps in the last 12 months. 0-1 is normal. 2+ major bumps/year signals an unstable API surface and high upgrade burden for consumers.
5. **Bus factor** — `gh api repos/OWNER/REPO/contributors?per_page=5` → if the top contributor accounts for > 80% of commits, bus factor is effectively 1. Check if the project has organizational backing (company sponsor, foundation membership) to mitigate.
6. **Migration path if tool dies** — Identify: (a) alternative tools that serve the same purpose, (b) how portable the data/config is (proprietary format vs standard), (c) blast radius — how many files/modules in the project would need to change. High blast radius + no alternatives = HIGH risk.

## Project Context Cross-Check

When Step 0 provides project constraints, verify against the project's existing dependency landscape:

- **Peer dep conflicts** — Check if the package has peer dependencies that conflict with existing deps. Run `npm ls` or check `peerDependencies` in the package's `package.json`. Conflicts may require `--legacy-peer-deps` or `overrides`.
- **Engine requirements** — Check `engines` field in the package's `package.json`. Verify Node version, npm version, and any platform requirements match the project.
- **`--legacy-peer-deps` impact** — If the project already uses `--legacy-peer-deps` (as BoomerAI does), adding another package with peer dep issues compounds the risk. Each override is a deferred compatibility problem.
- **Bus factor threshold** — Calibrate bus factor risk to the project's tolerance. A weekend hobby project can tolerate bus factor 1. A production app serving vulnerable users (seniors, healthcare) should require bus factor >= 2 or organizational backing.

## False Positives

- **Mature, stable tools** often have infrequent commits — check if the tool is "done" (low issue count, no bugs).
- **Monorepo packages** may show low individual stars but belong to a well-known organization.
- **Internal/enterprise tools** open-sourced may have low community adoption but strong backing.
- **Forks** may have low stars but inherit the parent repo's reputation — check the fork source.

## Anti-Patterns

- Recommending a repo based solely on it appearing in search results without checking stats
- Assuming a GitHub README's claims are accurate without verifying adoption signals
- Ignoring the existence of official/first-party solutions in favor of third-party tools
- Equating "recently created" with "actively maintained" — check commit frequency, not just creation date
- Relying on snapshot stats without checking trajectory — a project with 10K stars but declining activity is riskier than one with 2K stars and growing momentum
- Not checking transitive dependencies — a "small" package with 200 transitive deps has a large attack surface
