<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Source Attribution

Load this file when the quick scan flags source concerns: no citation, training-data-only claims, or outdated references.

## Verification Workflow

1. **Identify claim source** — For each factual claim in the recommendation, determine: is this from a live search, a fetched document, or training data?
2. **Live verification** — For training-data claims, perform a web search to verify against current sources.
3. **Freshness check** — If citing a URL, check the page's publication/update date. Content older than 12 months may be outdated for fast-moving tools. For AI/ML tools, use 6 months (see ai-ml-evaluation.md).
4. **Cross-reference** — Verify claims against at least 2 independent sources when possible (vendor docs + third-party review, or vendor docs + GitHub repo).
5. **Version alignment** — Ensure the cited documentation version matches the tool version being recommended.

## Severity: MEDIUM

- **No citation for factual claim**: Stating specific numbers (pricing, performance, adoption metrics) without any source. Must cite where the data came from.
- **Training data only**: Recommendation based entirely on training data with no live verification. State: "from training data — verify before using."
- **Stale source**: Citing documentation or articles more than 18 months old for actively developed tools. Check for newer versions.
- **Version mismatch**: Citing docs for v2.x when recommending v3.x, or vice versa. Features may have changed between major versions.
- **Broken/dead link**: Source URL returns 404 or has moved. The underlying claim may still be valid but needs a current source.

## Severity: LOW

- **Minor staleness**: Source is 6-12 months old but the specific claim is unlikely to have changed (e.g., architectural decisions, license type).
- **Single source**: Claim verified by one authoritative source (vendor docs). Acceptable for straightforward facts, flag for controversial claims.
- **Indirect citation**: Citing a blog post or tutorial instead of primary documentation. Acceptable if the blog is authoritative and recent.

## Source Quality Hierarchy

| Source Type | Reliability | Notes |
|-------------|-------------|-------|
| Official docs (current version) | Highest | Primary source for features, config, API |
| GitHub repo (README, code, releases) | High | Ground truth for implementation details |
| Vendor pricing page | High | Authoritative for current pricing |
| NVD / GitHub Advisories | High | Authoritative for security vulnerabilities |
| npm/PyPI registry metadata | High | Downloads, versions, maintainers |
| OpenSSF Scorecard | High | Automated security scoring for GitHub repos |
| OSV API (osv.dev) | High | Authoritative open-source vulnerability database |
| deps.dev | High | Google-maintained dependency graph and advisory data |
| Bundlephobia API | High | Accurate bundle size data for npm packages |
| Recent third-party benchmarks | Medium | Useful but may have methodology bias |
| Blog posts / tutorials | Medium | Check date and author credibility |
| Stack Overflow answers | Medium | Check vote count, date, and accepted status |
| Training data (no live lookup) | Low | May be outdated; always flag for verification |
| Marketing landing pages | Low | Biased toward positive framing; cross-reference with docs |
| Social media (X, Reddit) | Lowest | Anecdotal; useful for sentiment, not facts |

## Citation Patterns

### Good Citations
- "Stars: 12,340 (source: GitHub repo, checked 2026-02-17)"
- "Pricing: $0.006/min for STT (source: OpenAI pricing page)"
- "Feature available since v3.2 (source: changelog)"

### Bad Citations
- "It has good adoption" (no numbers, no source)
- "It costs about $2 per million characters" (no source, training data guess)
- "It supports TTS natively" (no verification of implementation)

## False Positives

- **Well-known, stable facts**: License type of major projects (MIT, Apache 2.0) doesn't need fresh verification every time.
- **Direct observation**: If you just fetched the README or pricing page in this conversation, that's a live source — no additional citation needed.
- **Mathematical derivations**: Calculating cost from verified unit prices doesn't need a separate source for the calculation.

## Anti-Patterns

- Presenting training-data knowledge as verified facts without disclosure
- Citing a source without checking if it's still current
- Using a single marketing page as the sole basis for capability claims
- Not distinguishing between "I know this from training" and "I verified this just now"
- Citing documentation for the wrong version of the tool
