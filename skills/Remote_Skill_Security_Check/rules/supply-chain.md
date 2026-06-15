# Supply Chain Attack Patterns

Detailed patterns for detecting supply chain risks in remote skill dependencies.

## HIGH — Typosquatting

Flag dependency names that resemble popular packages with subtle misspellings:

Common typosquatting targets:
- `requst` vs `request`
- `axois` vs `axios`
- `lodahs` vs `lodash`
- `expres` vs `express`
- `recat` vs `react`
- `typescirpt` vs `typescript`
- `eslintt` vs `eslint`
- `node-fecth` vs `node-fetch`
- `colros` vs `colors`
- `chalck` vs `chalk`

Detection heuristic: If a dependency name is within edit distance 1-2 of a top-1000 npm package, flag it.

## HIGH — Unpinned Dependency Versions

Flag loose version specifications that could pull malicious updates:

- `"*"` — any version
- `"latest"` — always latest
- `">= 1.0.0"` — unbounded upper range
- No lockfile committed alongside the skill
- `npm install` without `--save-exact`
- `pip install` without `==` version pin

## HIGH — Untrusted Sources

Flag dependencies from non-standard sources:

- `npm install https://example.com/package.tgz`
- `npm install git+https://random-site.com/repo.git`
- `pip install git+https://unknown.com/repo.git`
- Custom registry URLs: `--registry https://unknown-registry.com`
- `go get` from non-standard domains
- Tarball URLs instead of registry names
- GitHub URLs to forks with low star counts or no history

## MEDIUM — Private/Custom Registries

Flag use of non-standard registries (may be legitimate for enterprise):

- `.npmrc` with custom registry
- `publishConfig.registry` pointing to non-npmjs.org
- Yarn `.yarnrc` with custom registry
- pip `--index-url` pointing to non-pypi.org

## LOW — Missing Dependency Documentation

Flag when dependencies are required but not documented:

- Scripts that `require()` packages not listed in package.json
- `import` statements for undeclared dependencies
- Instructions to install packages with no explanation of why

## False Positive Indicators

- Dependencies from well-known scoped packages (`@types/`, `@babel/`, `@expo/`)
- Internal company scoped packages (`@company/package`) with documented registry
- Version ranges using caret `^` or tilde `~` (standard npm practice, low risk)
- DevDependencies used only in development/testing
