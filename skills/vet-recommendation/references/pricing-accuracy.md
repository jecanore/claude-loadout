<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Pricing Accuracy

Load this file when the quick scan flags pricing concerns: unverified cost claims, training-data-only pricing, or suspiciously low/high numbers.

## Verification Workflow

1. **Vendor pricing page** — Fetch the official pricing page directly using web fetch. This is the authoritative source.
2. **Unit verification** — Confirm the pricing unit matches the claim (per character vs per token vs per request vs per minute vs per hour).
3. **Tier identification** — Identify which tier/plan the claim refers to. Free tier? Starter? Enterprise? Pay-as-you-go?
4. **Date check** — Web search `"[vendor] pricing change" OR "[vendor] price increase"` for recent changes (last 12 months).
5. **Calculator validation** — If the vendor has a pricing calculator, use it to verify the claimed cost for the expected usage volume.
6. **Hidden costs** — Check for: setup fees, minimum commitments, overage charges, egress fees, support tiers, required add-ons.

## Severity: HIGH

- **Order-of-magnitude error**: Claimed price is 10x+ different from actual (e.g., $2/1M chars claimed vs $30/1M actual). This is a budget-breaking error.
- **Wrong pricing unit**: Confusing per-character with per-token, per-request with per-minute, per-GB with per-TB. Common with AI/ML services.
- **Outdated pricing**: Price changed significantly since training data cutoff. Vendor raised prices or changed pricing model entirely.
- **Missing critical cost component**: Quoting compute cost but omitting required storage, bandwidth, or API gateway costs that double the effective price.
- **Free tier confusion**: Claiming something is "free" when only a limited free tier exists that won't cover production usage.

## Severity: MEDIUM

- **Tier confusion**: Correct price but wrong tier — quoting enterprise pricing when the user needs starter, or vice versa.
- **Regional pricing differences**: Price varies by region and the quoted price is for a different region than the user's deployment.
- **Currency mismatch**: Quoting in wrong currency without conversion (USD vs EUR can be 10-15% different).
- **Promotional pricing**: Quoting a temporary promotional rate as the standard price.
- **Volume discount assumption**: Quoting volume pricing that requires commitment the user may not make.

## Severity: LOW

- **Minor variance**: Price within 20% of actual — could be rounding, recent small adjustment, or tier boundary difference.
- **Dated but directionally correct**: Old price but the magnitude and model are right (e.g., $0.005/req quoted, actual $0.006/req).

## False Positives

- **Custom/enterprise pricing** — some vendors don't publish enterprise rates; "contact sales" means the price genuinely varies.
- **Regional CDN pricing** — bandwidth costs vary significantly by region; a single number may be an average.
- **Open-source self-hosted** — cost is infrastructure-dependent; estimates are inherently approximate.
- **Usage-based pricing** — per-unit cost is correct but total depends on volume; the claim may be directionally right.

## Common Pricing Traps

| Trap | Example | How to Detect |
|------|---------|---------------|
| Per-char vs per-token | TTS services often price per character; LLMs per token. 1 token ≈ 4 chars. | Check the vendor's unit on their pricing page |
| Input vs output pricing | LLM providers charge differently for input and output tokens | Verify both rates, not just one |
| Per-1K vs per-1M | Quoting per-1K-tokens rate as per-1M-tokens | Check the denominator on the pricing page |
| Compute + markup | Raw GPU cost vs API service cost (10-50x markup typical) | Compare self-hosted vs API pricing |
| Monthly minimum | "$0.01/request" but $100/month minimum | Check for minimum spend requirements |
| Bandwidth/egress | Free compute but $0.09/GB egress | Check data transfer costs separately |
| Model alias price change | Provider changes which model an alias points to, changing the price | Compare alias vs pinned model pricing |
| Fine-tuning vs inference | Fine-tuning costs (training) quoted alongside inference costs (usage) — very different scales | Verify whether the quoted price is for training or inference |

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **Free tier vs expected usage** — will the project's usage exceed free tier limits?
- **Pricing units vs usage patterns** — match the vendor's pricing unit (per-request, per-token, per-minute) to the project's usage pattern
- **Budget constraints** — if mentioned in project context, verify the tool fits within budget at expected scale

## Anti-Patterns

- Quoting pricing from training data without verifying against the current pricing page
- Citing a single number without specifying the unit, tier, or date
- Comparing prices across vendors without normalizing units (tokens vs chars vs requests)
- Ignoring total cost of ownership (infrastructure, support, integration time) when comparing self-hosted vs SaaS
