<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Security Vulnerabilities

Load this file when the quick scan flags security concerns: known CVEs, advisory mentions, or breach history.

## Verification Workflow

1. **OSV API (primary)** — `POST https://api.osv.dev/v1/query` with body `{"package": {"name": "PACKAGE", "ecosystem": "npm"}}` → returns all known vulnerabilities for the package. Cross-references GitHub Advisories, NVD, and ecosystem-specific databases. Check `vulns[].severity` and `vulns[].affected[].ranges` for version impact.
2. **OpenSSF Scorecard** — `GET https://api.scorecard.dev/projects/github.com/OWNER/REPO` → returns scores for 18 automated security checks (code review, branch protection, dependency pinning, signed releases, etc.). Score below 4/10 is concerning. Score below 2/10 is a red flag. Check individual check results for specific weaknesses.
3. **GitHub Security Advisories** — `gh api repos/OWNER/REPO/security-advisories` or check the Security tab on the repo
4. **GitHub Advisory Database** — Web search `site:github.com/advisories "[package name]"` for ecosystem-wide advisories
5. **Tool security page** — Check if the tool has a `/security`, `SECURITY.md`, or security disclosure page
6. **Breach history & supply chain** — Web search `"[tool name] breach" OR "[tool name] vulnerability" OR "[tool name] exploit"` (limit to last 2 years). Check if dependencies have known issues: `npm audit` output, `pip audit`, or Dependabot alerts on the repo.

## Severity: CRITICAL

- **Active CVE with no patch**: Published CVE with CVSS >= 7.0, no fix version available. Exploitable in the wild.
- **Supply chain compromise**: Package was hijacked, maintainer account compromised, or malicious code injected (e.g., `event-stream` incident pattern).
- **Authentication/authorization bypass**: CVE allows unauthenticated access or privilege escalation.
- **Remote code execution**: CVE allows arbitrary code execution via the tool's normal interface.
- **Unpatched after 90 days**: CVE disclosed 90+ days ago with no fix, especially if the tool is actively maintained.

## Severity: HIGH

- **Patched CVE, user on vulnerable version**: CVE exists and is fixed, but the recommended version is the vulnerable one. Flag the safe version.
- **API key/secret exposure**: Tool's architecture exposes API keys in logs, system prompts, or client-side code (e.g., CVE-2026-25253 pattern).
- **Dependency with critical CVE**: The tool itself is fine, but a direct dependency has an unpatched critical CVE.
- **Security advisory without CVE**: Maintainer disclosed a security issue without a CVE number. Still a real vulnerability.
- **Marketplace/plugin ecosystem risks**: Tool has a plugin/extension marketplace with history of malicious submissions.
- **OpenSSF Scorecard below 2/10**: Extremely poor security practices across the board. High risk of future incidents.

## Severity: MEDIUM

- **Patched CVE, current version safe**: CVE existed but is fixed in the latest version. Note it for awareness.
- **Informational security advisory**: Low-impact issue, defense-in-depth concern, or theoretical attack vector.
- **Dependency audit warnings**: `npm audit` or similar shows moderate-severity issues in transitive dependencies.
- **Missing security practices**: No SECURITY.md, no security policy, no bug bounty, no signed releases.
- **OpenSSF Scorecard 2-4/10**: Below-average security practices. Specific failing checks should be noted.

## Severity: LOW

- **Resolved historical incident**: Past breach or vulnerability that was handled well (quick patch, transparent disclosure).
- **Theoretical attack surface**: Large codebase with many dependencies, increasing theoretical risk without specific evidence.

## Project Context Cross-Check

When Step 0 provides project constraints, verify against the project's security posture:

- **`npm audit` CI impact** — Will adding this package introduce new `npm audit` failures? If the project runs `npm audit` in CI, a package with known moderate-severity transitive vulnerabilities will break the build. Check before recommending.
- **Existing security overrides** — Check if `package.json` already has `overrides` for security patches. Adding more overrides compounds maintenance burden and can mask real issues.
- **Compliance requirements** — If the project has HIPAA, SOC2, or similar compliance requirements, any package with unpatched CVEs (even low severity) may trigger audit findings. Flag even LOW severity issues for compliance-sensitive projects.

## False Positives

- **CVE for a different product with the same name** — always verify the CPE (Common Platform Enumeration) matches.
- **CVE fixed in the version being recommended** — check the affected version range.
- **Test/development dependencies** — CVEs in devDependencies may not affect production.
- **Self-reported, already patched** — maintainer proactively disclosed and fixed; this is good security practice.

## Anti-Patterns

- Recommending a tool without searching for CVEs at all
- Finding a CVE but not checking if it's patched in the recommended version
- Ignoring transitive dependency vulnerabilities
- Treating "no CVEs found" as "proven secure" — absence of evidence is not evidence of absence
- Not checking the tool's security disclosure/response history
- Skipping OpenSSF Scorecard when the repo is publicly available on GitHub
