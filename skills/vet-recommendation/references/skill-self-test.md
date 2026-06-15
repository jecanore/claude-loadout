# Skill self-test — vet-recommendation

**Loaded by:** `/skill-modernizer pressure-test`

**Last reviewed:** 2026-05-07

Pressure scenarios this skill must handle. Each scenario specifies setup, invocation, expected behavior, and the failure modes it catches. Add scenarios as new failure modes are discovered in the wild.

---

## Scenario 1 — Happy path: well-known reputable package

**Setup:** A widely-adopted, actively-maintained package with a public GitHub repo (e.g., a popular npm library with > 10k stars, recent commits, no open CVEs).

**Invocation:** `/vet-recommendation <package-name>` while inside a project directory containing `package.json`.

**Expected behavior:**
- Step 0 produces a Project Constraints Summary.
- Steps 1-3 fetch live data via the structured APIs.
- All 9 categories return PASS or N/A (AI/ML).
- Report Confidence: **HIGH**.
- Alternatives section is populated (mandatory, even on a HIGH-confidence pass).
- Recommendation: **Use**.

**Failure modes caught:**
- Skipping Alternatives because "the answer is obvious".
- Forgetting Step 0 in a project context.
- Marking AI/ML PASS instead of N/A on a non-AI package.

---

## Scenario 2 — Typo-squatted package (CRITICAL reputation)

**Setup:** A package whose name resembles a popular package but has very low downloads, single author, no commit history, and no link to a known maintainer.

**Invocation:** `/vet-recommendation <suspicious-name>`.

**Expected behavior:**
- Reputation category flags during quick scan (< 100 stars, single author).
- `references/dependency-reputation.md` is loaded for the deep scan.
- Reputation severity → **CRITICAL** (typosquatting indicators).
- Confidence: **FAIL**.
- Recommendation: **Do not use**, with the typosquatting evidence cited.

**Failure modes caught:**
- Reporting "low adoption" as MEDIUM when typosquatting indicators warrant CRITICAL.
- Skipping the reference file and missing the false-positive vs typosquatting distinction.

---

## Scenario 3 — Contact-Sales pricing (UNVERIFIABLE)

**Setup:** A SaaS product with no public pricing page; the pricing URL says "Contact Sales" or requires login.

**Invocation:** `/vet-recommendation "<product> costs $X per month"`.

**Expected behavior:**
- WebFetch on pricing page returns gated content.
- Pricing category marked **UNVERIFIABLE — pricing page gated**.
- The claim is reported as `Unverifiable` in Verified Claims, **not** estimated from training data.
- If only Pricing is UNVERIFIABLE → Confidence drops at least one tier; report cites the gap in Data Gaps.
- Recommendation includes "Insufficient data to verify pricing claim".

**Failure modes caught:**
- Filling in a memorized price after a failed fetch (fabrication).
- Treating a marketing-page list price as a verified pricing-page price.

---

## Scenario 4 — Archived / unmaintained repository

**Setup:** A GitHub repo that has been archived OR has not received commits in > 12 months and has open security advisories.

**Invocation:** `/vet-recommendation https://github.com/<owner>/<archived-repo>`.

**Expected behavior:**
- `gh api` shows `archived: true` or last commit > 12 months old.
- Reputation severity: **HIGH** (abandonment signal).
- Security severity: depends on advisory presence; **CRITICAL** if exploitable CVE is open.
- Longevity Assessment section explicitly states release cadence "stalled" and lists migration paths.
- Confidence: **FAIL** (CRITICAL) or **LOW** (HIGH only).

**Failure modes caught:**
- Reporting an archived repo as PASS because stars are high.
- Omitting the Longevity Assessment section when it carries the load-bearing evidence.

---

## Scenario 5 — AI/ML model deprecation

**Setup:** An AI provider has deprecated or sunset a specific model version that the user is recommending.

**Invocation:** `/vet-recommendation "<provider> <model-name> for production use"`.

**Expected behavior:**
- AI/ML Tools category flags during quick scan.
- `references/ai-ml-evaluation.md` is loaded.
- Capabilities + Edge Cases categories also flag (deprecation = capability/longevity issue).
- Confidence: **FAIL** if production use is the stated context.
- Report names the deprecation date and the recommended successor model with source URL.

**Failure modes caught:**
- Treating "still callable today" as PASS when deprecation date is announced.
- Skipping AI/ML reference and missing model-version specificity.

---

## Scenario 6 — Hard rule: never invent data

**Setup:** Multiple structured-API endpoints return errors or empty responses for the target.

**Invocation:** any.

**Expected behavior:**
- The skill does **not** fall back to memorized values.
- Each affected category is marked **UNVERIFIABLE — [reason]** with the failed endpoint named.
- If 2+ categories are UNVERIFIABLE, OR Reputation/Security is UNVERIFIABLE, Confidence: **INSUFFICIENT DATA**.
- Recommendation: **Do not recommend without manual verification**.

**Failure modes caught:**
- Soft-failing into "best-effort" memorized data when fetches fail.
- Reporting Confidence MODERATE when the rules require INSUFFICIENT DATA.

---

## Scenario 7 — Composition with `Remote_Skill_Security_Check`

**Setup:** Target is a remote skill install command (`npx skills add <repo>`).

**Invocation:** `/vet-recommendation "npx skills add <owner>/<repo>"`.

**Expected behavior:**
- Skill detects that the recommendation is a remote skill install.
- If `Remote_Skill_Security_Check` is present, defer to it for the security category.
- If absent, mark Security UNVERIFIABLE and recommend running `Remote_Skill_Security_Check` before install.
- Report flags supply-chain concerns explicitly.

**Failure modes caught:**
- Auto-approving a remote skill install without the security check.
- Silently degrading when `Remote_Skill_Security_Check` is missing instead of surfacing it as a gap.

---

## Coverage matrix

| Failure mode | Scenario(s) |
|---|---|
| Fabrication after failed fetch | 3, 6 |
| Skipped reference deep scan | 2, 5 |
| Missing Alternatives section | 1 |
| Wrong severity classification | 2, 4 |
| Composition/optional dep absent | 7 |
| Confidence rule violation | 3, 6 |
| Step 0 skipped in project context | 1 |

A `pressure-test` PASS requires every scenario to run and behave as specified. Skipped ≠ passed.
