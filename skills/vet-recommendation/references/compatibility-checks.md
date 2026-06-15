<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Compatibility Checks

Load this file when the quick scan flags compatibility concerns: version mismatches, OS requirements, runtime dependencies, or compliance requirements.

## Verification Workflow

1. **Runtime requirements** — Check the tool's minimum Node.js, Python, Java, etc. version against the user's stack.
2. **OS compatibility** — Verify the tool supports the target OS (Linux distro for servers, macOS/Windows for dev). Check for architecture requirements (x86_64 vs ARM64).
3. **Dependency conflicts** — Check if the tool requires dependencies that conflict with existing project dependencies (e.g., incompatible peer dependencies).
4. **Version matrix** — Verify the tool works with the specific versions of frameworks/libraries in the user's stack. Check the tool's compatibility matrix or test matrix in CI.
5. **Compliance check** — If the project has compliance requirements (HIPAA, SOC2, GDPR, PCI-DSS), verify the tool meets them. Check for certifications, compliance docs, DPA availability.
6. **Geographic/legal** — Check for geographic restrictions, export controls, data residency requirements, or sanctions compliance.

## Severity: HIGH

- **Runtime incompatibility**: Tool requires Node.js 22+ but project uses Node.js 18. Or requires Python 3.12+ but project uses 3.9.
- **OS incompatibility**: Tool only runs on Linux but deployment target is Windows, or vice versa. Docker may mitigate but adds complexity.
- **Architecture mismatch**: Tool has no ARM64 build but target is Apple Silicon or ARM-based cloud (Graviton).
- **Breaking peer dependency**: Tool requires `react@18` but project uses `react@19`, or similar hard conflicts.
- **Compliance gap**: Project requires HIPAA compliance but tool has no BAA, or project requires GDPR compliance but tool has no DPA and stores data in US-only regions.
- **License incompatibility**: Tool uses AGPL and project is proprietary SaaS (AGPL requires source disclosure for network use).

## Severity: MEDIUM

- **Soft version constraint**: Tool recommends Node.js 20+ but may work on 18 with warnings. Test before relying on it.
- **Missing platform builds**: No pre-built binary for one target platform but builds from source. Adds CI complexity.
- **Transitive dependency version conflict**: Not a direct conflict but a shared transitive dependency at different versions. May cause subtle bugs.
- **Partial compliance**: Tool is SOC2 certified but not for the specific trust service criteria the project needs.
- **Data residency**: Tool stores data in regions that may not meet the project's data residency requirements. Check for region selection options.

## Severity: LOW

- **Minor version difference**: Tool tested with Node.js 20.11 but project uses 20.9. Likely fine but note it.
- **Optional feature incompatibility**: A non-essential feature of the tool doesn't work on the target platform.
- **Cosmetic compatibility**: Minor rendering or behavior differences across platforms that don't affect functionality.

## Compliance Quick Reference

| Requirement | Check For |
|-------------|-----------|
| HIPAA | BAA availability, encryption at rest/transit, audit logging, access controls |
| SOC2 | SOC2 Type II report, trust service criteria coverage |
| GDPR | DPA availability, EU data residency option, data export/deletion, consent management |
| PCI-DSS | Certified payment processing, no raw card data storage, tokenization |
| FedRAMP | FedRAMP authorization (Moderate/High), GovCloud availability |
| CCPA/CPRA | Data minimization, opt-out support, privacy policy, retention controls |

## Version Compatibility Patterns

### Semantic Versioning Risks
- **Major version bump** (v2 → v3): Breaking changes expected. Check migration guide.
- **Pre-release versions** (v3.0.0-beta.1): Not production-ready. Don't recommend for production without flagging.
- **0.x versions** (v0.9.4): No stability guarantees per semver. API may change without notice.

### Framework Compatibility
- React 18 vs 19: Check if the tool supports React 19's new features (compiler, actions)
- Next.js App Router vs Pages Router: Many tools only support one
- Expo SDK versions: Tools may require specific Expo SDK version ranges

## Mobile & Bundle Size

For React Native, Expo, and mobile projects, check these additional compatibility factors:

### Verification Steps

1. **Bundle size** — `GET https://bundlephobia.com/api/size?package=PACKAGE` → flag if gzip > 500KB
2. **Native module detection** — Check for `ios/` or `android/` directories in repo, `react-native.config.js`, or Expo config plugin requirement. Native modules add build complexity.
3. **Hermes compatibility** — Hermes engine restricts: `eval()`, `with` statements, some `Proxy` uses, and advanced `Intl` features. Check if the package relies on these.
4. **ESM vs CJS** — Check npm registry `exports` field. CJS-only packages can't tree-shake. ESM preferred.
5. **Expo directory** — Check `reactnative.directory` for Expo compatibility listing and community ratings.

### Mobile Severity

| Finding | Severity | Rationale |
|---------|----------|-----------|
| Native module without Expo config plugin | HIGH | Breaks Expo managed workflow; requires eject or custom dev client |
| Hermes-incompatible API usage | HIGH | Runtime crashes on iOS/Android with Hermes engine |
| Bundle size > 500KB gzipped | MEDIUM | Impacts app download size and cold start time |
| CJS-only (no ESM exports) | MEDIUM | Cannot tree-shake; inflates bundle |
| No listing on reactnative.directory | LOW | Less community validation, but may still work |

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **Expo managed workflow** — native modules require config plugin or custom dev client
- **NativeWind / className styling** — component must accept `className` prop or support `styled()` wrapper
- **Accessibility component requirements** — 56dp touch targets, font scaling support, no opacity for disabled states
- **Hermes engine** — no eval(), limited Proxy, restricted Intl
- **Install flags** — will the package install cleanly with project's required flags (e.g., `--legacy-peer-deps`)?

## False Positives

- **Docker isolation**: Many OS/runtime incompatibilities are resolved by running in Docker. Note this as a mitigation.
- **Polyfills/shims**: Some version gaps can be bridged with polyfills. Check if the tool provides or recommends them.
- **"Tested with" vs "requires"**: A tool may only list tested versions but work with others. Check issue tracker for reports from your version.
- **Transitive dependency resolution**: Package managers often resolve version conflicts automatically. Check if the conflict is real after resolution.

## Anti-Patterns

- Recommending a tool without checking its runtime requirements against the project's stack
- Ignoring compliance requirements when evaluating tools that handle user data
- Assuming Docker fixes all compatibility issues (it adds operational complexity)
- Not checking the tool's CI/test matrix for supported platform combinations
- Recommending a 0.x or beta tool for production without flagging the stability risk
