# Research sources — canonical URLs that drive `refresh`

**Loaded by:** `refresh`

**Version:** 1.0

---

## Preamble

This file is the canonical source list that drives the `refresh` subcommand. When `refresh` runs, it dispatches one parallel research agent per source defined here, then aggregates findings into a proposed diff against `rules/pattern-catalog.md` and `rules/scoring-rubric.md`.

The list itself is subject to staleness — URLs move, repos rename, blogs disappear. `refresh` therefore carries a meta-instruction: it audits and updates this file alongside the pattern catalog. Sources that go stale are marked `deprecated: true` (never deleted, to preserve history); replacement URLs are added by the user during refresh.

Sources are grouped by category. Within a category, `priority: primary` outweighs `priority: secondary` in conflict resolution.

---

## Source categories

Four categories cover the surface of skill-authoring guidance. Each entry has the fields described in `## Format`.

### 1. Official documentation

Authoritative guidance from the skill platform vendor. Highest weight in conflict resolution. These URLs change rarely; when they do, the change is the most important signal `refresh` can deliver.

- Use `kind: official-docs`.
- Default `priority: primary`.
- Default `query_strategy: fetch-and-parse`.

### 2. Reference implementations

Repositories maintained by the platform vendor that contain canonical example skills. Treated as primary because they are vendor-maintained, but they trail official docs when both speak to the same point.

- Use `kind: reference-implementation`.
- Default `priority: primary`.
- Default `query_strategy: recent-releases` for repos; `fetch-and-parse` for individual files.

### 3. Community skill repos

Third-party collections of skills authored by experienced practitioners. Useful for emerging patterns that haven't yet made it into official docs. Lower priority because they reflect one author's opinion, not platform consensus.

- Use `kind: community-skill-repo`.
- Default `priority: secondary`.
- Default `query_strategy: recent-releases`.

### 4. Engineering blog posts

Long-form articles from the platform vendor's engineering team or other reputable sources. Useful for rationale and design intent that docs omit. Sometimes ahead of docs, sometimes behind — date-check carefully.

- Use `kind: engineering-blog`.
- Default `priority: secondary` (primary only when explicitly authored by the platform vendor and clearly still current).
- Default `query_strategy: keyword-search`.

---

## Conflict resolution policy

When two sources disagree on a finding:

1. **Priority outweighs recency.** A primary source from last year outweighs a secondary source from this week.
2. **Within the same priority, more-recent outweighs older.** Use the source's last-modified or release date when available; fall back to the agent's `fetched_at` timestamp.
3. **If still ambiguous,** `refresh` records the disagreement in `RefreshPlan.conflicts[]` and surfaces it explicitly in the diff preview. The user adjudicates; the conflicted hunk is held back from auto-apply.

`refresh` never picks arbitrarily on conflicts.

---

## Source staleness detection

For each source, the agent reports a `source_health` value:

| `source_health` | Meaning | Action |
|---|---|---|
| `ok` | URL fetched, content recognized as on-topic | Update `last_verified`. |
| `redirected` | URL returned a 3xx to a different domain or path | Surface in diff: propose updating `url` or marking deprecated. |
| `404` | URL returned 404 (or equivalent) | After two consecutive `404` results, propose `deprecated: true`. |
| `content-mismatch` | URL fetched but content no longer mentions skills | Surface in diff: propose deprecation with `deprecated_reason: "content drifted"`. |
| `failed` | Network error, timeout, parse error | Aggregate as warning; not a staleness signal on its own. |

When `refresh` proposes a staleness-driven edit, it asks the user to either confirm deprecation or paste a replacement URL. The replacement URL becomes a new source entry; the deprecated entry is preserved.

---

## Adding a source

To extend this catalog:

1. Pick a category and use the matching `kind` value.
2. Fill in every field listed in `## Format`. `last_verified` may be set to the current ISO timestamp at add-time, or left as `<ISO-timestamp>` and refreshed on next run.
3. Note in `notes:` any quirks: rate limits, paywalls, login requirements, or known content-mismatch risks.
4. Run `refresh` once to confirm the new source returns useful findings. If it returns zero findings across two consecutive refreshes, reconsider whether it belongs.

---

## Removing a source

Do not delete entries. Mark with:

```yaml
deprecated: true
deprecated_reason: "<short explanation>"
deprecated_at: <ISO-timestamp>
```

`refresh` ignores deprecated sources during dispatch but logs them in the report so the trail is visible. Preserving history matters because a deprecated URL may come back, and the audit log of why it was deprecated saves a future refresh from re-discovering the same problem.

---

## Format

```yaml
sources:
  - name: <short-identifier>
    url: <canonical-URL-or-placeholder>
    kind: official-docs | reference-implementation | community-skill-repo | engineering-blog
    priority: primary | secondary
    query_strategy: fetch-and-parse | keyword-search | recent-releases
    last_verified: <ISO-timestamp>
    notes: "<free text>"
```

Optional fields when deprecated:

```yaml
    deprecated: true
    deprecated_reason: "<short explanation>"
    deprecated_at: <ISO-timestamp>
```

---

## Default source list

The URLs below are placeholders for the user to confirm or replace during the initial `refresh`. `refresh` will surface any that fail health checks and prompt for replacement.

```yaml
sources:
  - name: anthropic-skills-docs
    url: <replace-with-current-anthropic-skills-docs-url>
    kind: official-docs
    priority: primary
    query_strategy: fetch-and-parse
    last_verified: <ISO-timestamp>
    notes: "Authoritative source for skill structure and lifecycle. The user should confirm this URL during the first refresh; vendor docs paths shift as products evolve."

  - name: claude-agent-sdk-docs
    url: <replace-with-current-agent-sdk-docs-url>
    kind: official-docs
    priority: primary
    query_strategy: fetch-and-parse
    last_verified: <ISO-timestamp>
    notes: "Skills are loaded by the agent SDK; SDK docs sometimes carry conventions docs do not. Confirm URL during initial refresh."

  - name: anthropics-skills-repo
    url: https://github.com/anthropics/skills
    kind: reference-implementation
    priority: primary
    query_strategy: recent-releases
    last_verified: <ISO-timestamp>
    notes: "Vendor-maintained example skills. Watch recent commits and releases for changes to canonical skill structure."

  - name: anthropic-engineering-blog
    url: https://www.anthropic.com/engineering
    kind: engineering-blog
    priority: secondary
    query_strategy: keyword-search
    last_verified: <ISO-timestamp>
    notes: "Search for 'skills' or 'agent skills'. Treat as primary only when the post is explicitly about skill authoring and clearly current."

  - name: superpowers-repo
    url: https://github.com/obra/superpowers
    kind: community-skill-repo
    priority: secondary
    query_strategy: recent-releases
    last_verified: <ISO-timestamp>
    notes: "Well-known community collection. Source for emerging patterns, especially TDD discipline (Iron Law, RED/GREEN/REFACTOR). Lower priority than vendor sources."

  - name: community-skill-repo-secondary
    url: <replace-with-second-community-repo-url>
    kind: community-skill-repo
    priority: secondary
    query_strategy: recent-releases
    last_verified: <ISO-timestamp>
    notes: "Second community repo for cross-validating community findings. Add a URL during initial refresh; if no clear second exists, mark deprecated."

  - name: skill-discovery-tool-docs
    url: <replace-with-find-skills-or-equivalent-docs-url>
    kind: reference-implementation
    priority: secondary
    query_strategy: fetch-and-parse
    last_verified: <ISO-timestamp>
    notes: "Documentation for the skill-discovery tooling (e.g., a find-skills equivalent). Useful for surface conventions about skill metadata and triggers."

  - name: anthropic-cookbook
    url: https://github.com/anthropics/anthropic-cookbook
    kind: reference-implementation
    priority: secondary
    query_strategy: keyword-search
    last_verified: <ISO-timestamp>
    notes: "Vendor cookbook. Search for 'skills' or 'agent' content. Treat findings as design-pattern signal; structural conventions still come from the skills repo."
```

---

## Maintenance notes

- The default list above is a starting point. Treat the placeholder URLs as TODO items for the first `refresh`.
- Eight entries is a reasonable working size: enough surface for cross-validation, few enough that parallel dispatch stays fast.
- When pruning, prefer marking `deprecated: true` over deleting. The deprecation reason is itself a finding next time `refresh` runs against a similar source.
- When two community repos consistently surface the same findings, consider deprecating the lower-quality one to reduce noise — but always with a reason recorded.
