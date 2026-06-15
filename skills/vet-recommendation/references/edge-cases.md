<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Edge Cases

Load this file when the quick scan flags edge case concerns: recent acquisitions, license changes, active incidents, or name collisions.

## Verification Workflow

1. **License check** — Fetch the LICENSE file from the repo. Compare against the license shown on npm/PyPI. Web search `"[tool name] license change"` for recent changes.
2. **Acquisition/ownership** — Web search `"[tool name] acquired" OR "[tool name] acquisition" OR "[company name] buys [tool name]"` to check for recent ownership changes.
3. **Active incidents** — Check the tool's status page (if it's a service). Web search `"[tool name] outage" OR "[tool name] incident" OR "[tool name] down"` for recent issues.
4. **Name collision** — Verify you have the right tool. Search the specific registry (npm, PyPI, GitHub) to confirm the package name matches the intended project.
5. **Sunset/EOL** — Web search `"[tool name] sunset" OR "[tool name] end of life" OR "[tool name] discontinued"` for shutdown announcements.

## Severity: HIGH

- **License bait-and-switch**: Tool was open-source (MIT, Apache) but recently changed to a restrictive license (SSPL, BSL, proprietary). This can affect production use.
  - Notable examples pattern: Check if the tool follows the HashiCorp (BSL), Elastic (SSPL), or MongoDB (SSPL) pattern.
  - Verify: Fetch current LICENSE file AND check recent announcements.
- **Recent acquisition with strategy change**: Tool was acquired and new owner is changing direction (feature removal, price increases, platform restrictions).
  - Check: Press releases, blog posts from the acquiring company, community reaction.
- **Active incident affecting production**: The service is currently experiencing an outage, data loss, or security incident that would affect new adopters.
- **Sunset announced**: Tool has announced end-of-life or migration to a replacement. Don't recommend tools with a known expiration date without flagging it.
- **Name collision / typosquatting**: Multiple packages/tools share the same or similar names. Verify you're recommending the correct one.
  - Check: npm `https://www.npmjs.com/package/[name]` → verify author, description, repo link
  - Check: GitHub → verify the org/user matches expectations

## Severity: MEDIUM

- **Ownership change without clear impact**: Tool was acquired but new owner hasn't made disruptive changes yet. Flag for monitoring.
- **License edge case**: Tool is dual-licensed or has a community/enterprise split. Verify which license applies to the user's use case.
- **Stale community after acquisition**: Tool was acquired, maintainers left, community activity dropped. May signal future abandonment.
- **Rewrite in progress**: Major version rewrite announced. Current version works but may become unsupported when the rewrite ships.

## Severity: LOW

- **Minor controversy**: Community disagreement about direction, but tool remains functional and maintained.
- **Completed migration**: Tool went through a disruptive change (license, ownership) but has stabilized. Note the history for awareness.

## License Quick Reference

| License | Commercial OK | SaaS OK | Copyleft | Notes |
|---------|--------------|---------|----------|-------|
| MIT | Yes | Yes | No | Most permissive |
| Apache 2.0 | Yes | Yes | No | Patent grant included |
| BSD 2/3 | Yes | Yes | No | Similar to MIT |
| ISC | Yes | Yes | No | Simplified MIT |
| GPL v2/v3 | Depends | Depends | Yes | Derivatives must be GPL |
| AGPL v3 | Depends | No* | Yes | Network use triggers copyleft |
| LGPL | Yes | Yes | Partial | Library linking exception |
| SSPL | Depends | No | Yes | MongoDB's license; OSI rejected |
| BSL | Depends | No* | Custom | Converts to open source after delay |
| Proprietary | Check terms | Check terms | N/A | Read the EULA carefully |

*SaaS use may require source disclosure or commercial license.

## Name Collision Verification

When the tool name is common or short:
1. Search the exact name on the target registry (npm, PyPI, crates.io)
2. Verify the package's GitHub repo link matches the intended project
3. Check the author/organization matches expectations
4. Compare the README description to what you think the tool does
5. If multiple packages share the name, specify the full qualified name (org/package)

## False Positives

- **License change that doesn't affect the use case**: SSPL change doesn't matter if you're using the tool internally, not offering it as a service.
- **Acquisition by a reputable company**: Some acquisitions improve a tool (better funding, more developers). Check if the community reaction is positive.
- **Historical incident, fully resolved**: A past outage doesn't mean the service is unreliable. Check post-mortem quality and improvements made.
- **Fork available**: If the original changed license, a community fork under the old license may exist (e.g., OpenSearch from Elasticsearch).

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **License compatibility** — is the tool's license compatible with the project's license and distribution model?
- **Compliance requirements** — does the project have compliance requirements (from CLAUDE.md) that the tool must meet?
- **Existing dependency overlap** — does the tool duplicate functionality already provided by an existing dependency?

## Anti-Patterns

- Not checking the current license, relying on training data which may predate a change
- Ignoring acquisition news that could signal strategic shifts
- Recommending a tool during an active incident without checking status pages
- Not verifying the exact package identity when names are generic or similar
- Assuming a "well-known" tool name always refers to the same project
