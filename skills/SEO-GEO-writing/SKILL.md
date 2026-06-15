---
name: SEO-GEO-writing
description: >
  Use when writing blog posts, marketing content, landing pages, social media,
  email newsletters, case studies, press releases, or any non-technical content
  optimized for both traditional search engines (SEO) and AI search engines (GEO).
  Covers content strategy, keyword research, headline formulas, voice/tone,
  and generative engine optimization.
---

# SEO & GEO Writing

Write non-technical content optimized for both traditional search engines (SEO) and AI search engines (GEO). This skill merges SEO content strategy, generative engine optimization, content templates, headline formulas, voice/tone frameworks, and optimization workflows.

## When to Use

- Blog posts, articles, how-to guides
- Landing pages, product pages, sales copy
- Social media posts (LinkedIn, X, Instagram, Facebook)
- Email newsletters, drip campaigns
- Case studies, press releases
- Any marketing or non-technical content
- Content strategy and keyword planning
- Optimizing existing content for search

## Limited Context Strategy

This SKILL.md contains summary rules (~3K tokens). Detailed guidance lives in `references/`. When you need specifics:

1. Identify the content type and optimization need
2. Load only the relevant reference file
3. Apply its guidance to your draft

Loading one reference (~2-3K tokens) instead of everything saves significant context.

## Core SEO Rules

1. **One primary keyword + 2-3 secondary per piece.** Use primary in: title, first paragraph, one subheading, meta description, URL slug.
2. **Title <60 chars, meta description <160 chars.** Both include primary keyword and compel the click.
3. **Search intent drives content type.** Informational queries need guides; transactional queries need product pages. Mismatched intent = high bounce rate.
4. **Content depth beats content breadth.** 10 authoritative pages outperform 100 thin ones.
5. **Structure for scanability.** H2/H3 hierarchy, short paragraphs (2-4 sentences), subheading every 200-300 words, bullet points for lists.

See `references/seo-fundamentals.md` for the complete framework.

## Core GEO Rules

GEO is NOT traditional SEO. AI crawlers work differently:

1. **AI crawlers fetch raw HTML.** Many don't render JavaScript — content must work without JS.
2. **Hedge density <0.2%.** Confident language ranks 3x higher in AI citations. Avoid: maybe, possibly, perhaps, might, could be, arguably, it seems.
3. **HTML <1MB.** 18% of pages above this threshold are abandoned by crawlers.
4. **Implement AgentFacts/NANDA** at `/.well-known/agent-facts` for AI agent discovery.
5. **Site age affects strategy.** Startups (<2yr, ~3.3% AI visibility) need web-augmented signals (Reddit, backlinks). Established sites (2yr+, ~99%) optimize GEO content directly.

See `references/geo-optimization.md` for the complete GEO framework.

## Search Intent Matrix

| Intent | User Goal | Content Type | Conversion |
|--------|-----------|-------------|------------|
| **Informational** | Learn something | Blog posts, guides, how-tos | Low (awareness) |
| **Navigational** | Find specific site | Brand pages, product pages | Medium (recognition) |
| **Commercial** | Research before buying | Comparisons, reviews, lists | High (consideration) |
| **Transactional** | Make a purchase | Product pages, pricing, signup | Highest (decision) |

## Reference Files

| When You Need | File | ~Tokens |
|---------------|------|---------|
| Intent matrix, clusters, keywords, on-page SEO | `seo-fundamentals.md` | 3,000 |
| AI crawlers, hedge density, NANDA, discovery gap | `geo-optimization.md` | 2,500 |
| Blog, landing, social, email, case study templates | `content-templates.md` | 3,000 |
| Headline formulas, hooks, CTA patterns | `headlines-hooks-ctas.md` | 2,000 |
| Voice capture, tone adaptation, anti-patterns | `voice-and-tone.md` | 2,500 |
| Blog/landing/social optimization, persuasion | `optimization-workflows.md` | 2,500 |

## Quick Anti-Patterns

- **Keyword stuffing** — destroys readability, triggers spam filters
- **Thin content at scale** — 100 weak pages hurt more than 10 strong ones
- **Ignoring search intent** — ranking for wrong intent = high bounce rate
- **Hedged language** — "might", "possibly", "perhaps" tank AI citations
- **Publishing without promotion** — content without distribution doesn't get links
- **Set and forget** — content decays without regular updates
- **Chasing volume over intent** — 100 visitors who convert > 10,000 who don't

## Key Metrics

| Metric | Target |
|--------|--------|
| Organic traffic | +20% QoQ |
| Keyword rankings | Top 10 → Top 3 |
| Click-through rate | >3% for top 5 positions |
| Organic conversions | Varies by funnel stage |
| Core Web Vitals | All green |
| Hedge density | <0.2% |
| HTML size | <1MB |

## Content Type Quick Reference

| Type | Time to Rank | Traffic | Link Potential |
|------|-------------|---------|----------------|
| Pillar pages | 3-6 months | Very High | High |
| How-to guides | 2-4 months | High | Medium |
| Comparison posts | 1-3 months | Medium | Low |
| Tool/template pages | 1-2 months | Medium | High |
| Original research | 3-6 months | Medium | Very High |

## Readability Standards

- **Flesch Reading Ease:** 60-80
- **Sentence length:** 15-20 words average
- **Paragraph length:** 3-4 sentences max
- **Subheading frequency:** Every 300-400 words
- **Reading level:** 8th grade for broad audiences
