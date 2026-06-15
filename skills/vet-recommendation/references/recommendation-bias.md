<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Recommendation Bias

Load this file when the quick scan flags bias concerns: no alternatives presented, familiarity-driven choice, or over-engineering.

## Verification Workflow

Alternatives analysis is **mandatory** for every recommendation — not just when bias is detected.

1. **First-party check** — Before any third-party recommendation, search if the platform/framework has a built-in or official solution.
2. **Alternatives search** — Web search `"[tool purpose] alternatives [current year]"` OR `"[tool name] vs [current year]"` to identify at least 2-3 alternatives. Always include the current year in the query for fresh results.
3. **Simpler alternative** — Identify at least one simpler/lighter alternative. Could the requirement be met with less complexity?
4. **Established alternative** — Identify at least one more established/mature alternative. What would the conservative choice be?
5. **Comparison table** — Populate the Required Alternatives Table (below) with all candidates. This table is REQUIRED in the report.
6. **Fit-for-purpose** — Use the Right-Sizing Guide to match tool complexity to project stage and actual requirements.
7. **Lock-in assessment** — Check: proprietary data formats, migration difficulty, API portability, contract terms.

## Severity: LOW

These findings don't block adoption but indicate the recommendation may not be optimal. The Alternatives section in the report is REQUIRED regardless of severity level. Even when no bias is detected, the comparison table must be populated.

- **No alternatives considered**: Recommending a single tool without mentioning viable alternatives. At minimum, note 1-2 alternatives with brief trade-offs.
- **Familiarity bias**: Recommending a tool primarily because it's well-known or frequently mentioned in training data, not because it's the best fit. Check if newer or more appropriate options exist.
- **Over-engineering**: Recommending a complex, feature-rich tool when a simpler solution meets all requirements. Kubernetes for a single-server app. Enterprise DB for a prototype.
- **Under-engineering**: Recommending a tool that will need replacement soon because it can't scale to known near-term requirements.
- **Vendor lock-in without disclosure**: Recommending a tool with significant lock-in (proprietary formats, no export, custom API) without noting the exit cost.
- **Hype-driven**: Recommending the latest trending tool without evaluating maturity. Popular on HN/X != production-ready.

## Bias Detection Patterns

| Bias Type | Signal | Mitigation |
|-----------|--------|------------|
| Familiarity | Recommending the same tool across unrelated projects | Search for purpose-specific alternatives |
| Recency | Recommending a tool that's trending right now | Check age, stability, adoption curve |
| Authority | Recommending because a respected developer uses it | Evaluate on technical merits for this project |
| Confirmation | Finding evidence that supports a pre-selected tool | Search for criticism and failure modes too |
| Sunk cost | Recommending to keep using a tool the team already invested in | Compare switching cost vs ongoing cost of staying |
| Complexity | Recommending the most powerful/flexible option | Match solution complexity to problem complexity |

## Alternatives Analysis Template

When presenting alternatives, use this structure:

| Criterion | [Recommended] | [Alternative A] | [Alternative B] |
|-----------|--------------|-----------------|-----------------|
| Fits requirement X | Yes/Partial/No | Yes/Partial/No | Yes/Partial/No |
| Adoption/maturity | [stats] | [stats] | [stats] |
| Cost | [verified] | [verified] | [verified] |
| Lock-in risk | Low/Medium/High | Low/Medium/High | Low/Medium/High |
| Learning curve | Low/Medium/High | Low/Medium/High | Low/Medium/High |
| Trade-off | [main trade-off] | [main trade-off] | [main trade-off] |

## Right-Sizing Guide

| Project Stage | Prefer | Avoid |
|---------------|--------|-------|
| Prototype/MVP | Simple, fast to integrate, low config | Enterprise tools, complex setup |
| Early startup | Flexible, low cost, good docs | High lock-in, expensive minimums |
| Growth stage | Scalable, proven at scale, good support | Unproven tools, single-author projects |
| Enterprise | Compliant, supported, auditable | Tools without SLAs, undocumented APIs |

## False Positives

- **Genuine best-in-class**: Sometimes one tool is clearly superior for the use case. Not every recommendation needs 3 alternatives if the pick is well-justified.
- **Stack-mandated choices**: If the project uses Next.js, recommending Vercel deployment isn't bias — it's alignment. Note the synergy.
- **No real alternatives exist**: For niche requirements, there may genuinely be only 1-2 options. Note the limited market.

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **CLAUDE.md mandated tools** — respect tools/patterns explicitly required by the project (e.g., NativeWind for styling, Zustand for state). Don't recommend alternatives to mandated tools.
- **Complexity vs project stage** — match recommendation complexity to the project's maturity level
- **Existing patterns** — prefer tools that follow the project's established patterns (barrel exports, feature module structure, etc.)

## Anti-Patterns

- Recommending a tool without explaining why it was chosen over alternatives
- Defaulting to the most popular option without checking fit
- Dismissing simpler solutions without justification
- Recommending tools that solve problems the project doesn't have
- Ignoring the team's existing expertise and familiarity (relevant factor, not sole factor)
