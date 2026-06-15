<!-- Last reviewed: 2026-02-27 -->
<!-- Version: 2.0 -->

# AI/ML Tool Evaluation

Load this file when the quick scan flags AI/ML concerns: model deprecation, SDK instability, provider lock-in, or streaming requirements.

## Verification Workflow

1. **Model deprecation policy** — Search provider docs for model lifecycle/availability guarantees. Check for published deprecation schedules (e.g., OpenAI's model deprecation notices). Web search `"[provider] model deprecation" OR "[provider] model lifecycle"`.
2. **SDK stability scoring** — Check the tool's changelog/releases for breaking changes in the last 12 months. Count major/breaking changes:
   - 0-1 breaking changes = Stable
   - 2-3 breaking changes = Moderate instability
   - 4+ breaking changes = Unstable — high maintenance burden
3. **Streaming/real-time support** — Verify WebSocket, SSE, or chunked transfer support for voice/chat use cases. Check docs for streaming API endpoints. Web search `"[tool] streaming" OR "[tool] real-time" OR "[tool] websocket"`.
4. **Provider abstraction** — Does the tool support multiple AI providers, or is it single-vendor? Check for provider switching, fallback routing, or multi-model support. Single-vendor lock-in is HIGH risk for production systems.
5. **API versioning** — Check if the tool uses pinned API versions or floating aliases (e.g., `gpt-4` vs `gpt-4-0613`). Floating aliases can change behavior silently. Search docs for version pinning guidance.
6. **Data handling** — Check the provider's data retention policy, training-on-input policy, and privacy commitments. Web search `"[provider] data retention" OR "[provider] training data policy"`. Check for SOC2/HIPAA compliance if needed.

## Severity: CRITICAL

- **Dependent model deprecated with no migration**: The model the tool relies on has been deprecated or sunset, and no migration path exists. The tool will stop working.
- **Active data breach at provider**: The AI provider has an active, unresolved security incident affecting customer data.

## Severity: HIGH

- **2+ breaking SDK changes in 6 months**: Rapid instability signals an immature or poorly governed API surface. High maintenance burden.
- **Single-provider lock-in with no abstraction**: Tool only works with one AI provider and has no abstraction layer. Provider outage = total outage. Provider price change = no negotiating leverage.
- **No streaming for real-time use case**: Project requires real-time voice/chat but the tool only supports request-response. Latency will be unacceptable.
- **Floating model alias with no pin option**: Tool uses aliases like `gpt-4` that the provider can silently redirect. Behavior changes without code changes.

## Severity: MEDIUM

- **SDK < 12 months old at 0.x version**: Pre-1.0 SDK with no stability guarantees. API may change without notice.
- **Comparison source > 6 months old**: AI landscape changes rapidly. Benchmarks and comparisons over 6 months old may not reflect current capabilities.
- **Prompt/schema lock-in without documented migration**: Tool uses proprietary prompt formats or conversation schemas with no documented way to export or migrate.
- **No published latency data**: Tool claims real-time performance but provides no P50/P95/P99 latency benchmarks.

## AI-Specific Lock-In Vectors

| Vector | What Gets Locked In | Migration Difficulty |
|--------|--------------------|--------------------|
| Prompt templates | Vendor-specific prompt syntax, system messages | Low — rewrite prompts |
| Fine-tuned models | Training data, model weights, tuning config | High — must retrain from scratch |
| Conversation schema | Message format, role definitions, metadata | Medium — transform schema |
| Latency profile | Architecture tuned for specific provider's response times | Medium — retest and retune |
| Embedding space | Vector representations from a specific model | High — re-embed entire corpus |
| Rate limit design | Retry logic, queue sizing built for specific limits | Low — reconfigure |

## Staleness Rules (AI/ML specific)

AI tools move faster than traditional software. Use shorter staleness windows:

| Data Type | Max Age |
|-----------|---------|
| Model pricing | 3 months |
| SDK features / API surface | 6 months |
| Model benchmarks / quality | 6 months |
| Provider comparisons | 6 months |

## Project Context Cross-Check

When Step 0 provides project constraints, verify:
- **Real-time voice/chat** → streaming support is REQUIRED, not optional
- **Multi-provider requirement** → abstraction layer must exist
- **User conversation storage** → check provider data retention policy against project's privacy requirements
- **Expo / React Native** → verify SDK works in Hermes runtime (no eval, limited Proxy support)
- **Accessibility requirements** → verify TTS/STT output quality is sufficient for target users

## False Positives

- **Intentional single-provider**: If the project explicitly chose a single provider (documented in CLAUDE.md), single-provider lock-in is a known trade-off, not a finding.
- **0.x SDK with stable API surface**: Some SDKs stay at 0.x for years with minimal breaking changes. Check actual changelog, not just version number.
- **Self-hosted models**: Lock-in concerns are reduced when the model runs on project infrastructure. Provider outage risk doesn't apply.

## Anti-Patterns

- Recommending an AI tool without checking the underlying model's deprecation status
- Assuming "latest model" aliases are stable references
- Ignoring data retention policies when the project handles sensitive user data
- Treating AI SDK version numbers the same as traditional library version numbers (AI SDKs break more often)
- Not verifying streaming support for real-time applications
