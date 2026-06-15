<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# Capability Verification

Load this file when the quick scan flags capability concerns: "native"/"built-in" claims, beta features presented as stable, or marketing language masking actual implementation.

## Verification Workflow

1. **Official docs check** — Fetch the tool's documentation page for the claimed feature. Verify it exists, is documented, and matches the claim.
2. **Implementation check** — Determine if the feature is truly built-in or delegates to an external API/service. Check architecture docs, source code, or configuration.
3. **Stability check** — Look for labels: "beta", "preview", "experimental", "alpha", "early access", "coming soon" on the feature page.
4. **Deprecation check** — Web search `"[tool] [feature] deprecated" OR "[tool] [feature] removed" OR "[tool] [feature] end of life"`.
5. **Version check** — Verify the feature exists in the specific version being recommended, not just "in the tool" generically.
6. **Changelog/release notes** — Check recent changelogs for the feature being added, changed, or removed.

## Key Terminology

| Term | What It Actually Means | When to Use |
|------|----------------------|-------------|
| **Native** | Implemented in the tool's own codebase, no external dependency | Only when verified via source/docs |
| **Built-in** | Ships with the tool, no separate install needed | Only when the feature requires no external service |
| **Integrated** | Works with the tool but requires external service/API | When the tool configures and calls an external API |
| **Orchestrated** | Tool coordinates external services on the user's behalf | When the tool routes to multiple external providers |
| **Supported** | Compatible with, may need configuration | Generic — prefer more specific terms |

## Severity: MEDIUM

- **"Native" when it's external**: Describing a feature as native/built-in when it actually delegates to an external API (e.g., "native TTS" that calls OpenAI's TTS API). Use "integrated" or "orchestrated" instead.
- **Beta presented as GA**: Feature is in beta/preview but presented as production-ready. Flag the stability status.
- **Deprecated feature**: Feature exists but is marked deprecated, end-of-life, or scheduled for removal.
- **Marketing vs reality**: Vendor landing page claims a capability that docs reveal is limited, partial, or requires enterprise tier.
- **Conditional availability**: Feature exists but only on certain platforms, tiers, or with specific configuration.

## Severity: LOW

- **Minor terminology imprecision**: Feature works as described but the specific technical term used is slightly off. Doesn't affect the recommendation.
- **Preview feature with clear timeline**: Feature is in preview but has a published GA date and is stable in practice.

## Verification Patterns by Feature Type

### API/Service Features
- Does the tool call an external API? → It's "integrated", not "native"
- Does the user need their own API key? → It's "bring your own", not "built-in"
- Does the tool provide a wrapper/abstraction? → It's "orchestrated"

### Self-Hosted Features
- Does it require a separate binary/container? → It's a "companion service", not "built-in"
- Does it bundle the dependency in its install? → It's "bundled" (acceptable to call built-in)
- Does it require separate configuration? → Specify the setup requirement

### Platform Features
- Is it a first-party feature or a plugin? → Specify "core" vs "plugin/extension"
- Is it available on all platforms or just some? → Specify platform availability
- Does it require a specific tier/license? → Specify the tier requirement

## False Positives

- **Reasonable abstraction**: A tool that bundles and manages an external service transparently (e.g., Electron bundles Chromium — calling it "built-in browser" is acceptable).
- **Industry-standard terminology**: Some domains use "native" loosely (e.g., "native mobile app" for React Native). Context matters.
- **Feature that was external but is now native**: Tool may have internalized a previously external dependency. Check current version.

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **CLAUDE.md banned patterns** — does the tool require patterns the project explicitly bans? (e.g., dropdowns, Alert.alert(), opacity on disabled, raw Pressable)
- **className / accessibilityLabel support** — does the component accept className prop (for NativeWind) and support accessibilityLabel?
- **Font scaling** — does the component respect dynamic font scaling, or does it hardcode fontSize?
- **Touch target size** — do interactive elements meet the project's minimum touch target (e.g., 56dp)?
- **Theming** — does the component support the project's theming approach (semantic color tokens, high-contrast mode)?

## Anti-Patterns

- Describing any feature as "native" without checking the implementation
- Presenting beta/preview features without noting their stability status
- Using vendor marketing copy as the basis for capability claims
- Assuming a feature exists in all versions because it exists in the latest version
- Ignoring platform, tier, or configuration requirements when describing capabilities
