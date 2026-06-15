# Generative Engine Optimization (GEO)

Optimize content for AI search engines — ChatGPT, Perplexity, Claude, Gemini.

## GEO vs SEO

GEO is NOT traditional SEO. Key differences:

| Aspect | SEO | GEO |
|--------|-----|-----|
| Crawlers | Googlebot renders JS | Many AI crawlers fetch raw HTML only |
| Ranking signals | Backlinks, authority, keywords | Confidence, entity density, structure |
| Size limits | Flexible | 1MB HTML hard ceiling |
| Content evaluation | Algorithmic relevance | Linguistic confidence analysis |
| Discovery | Index → SERP | Training data + real-time search |

## Hedge Density

The single most impactful GEO metric. AI systems rank confident, declarative content 3x higher than hedged content.

### Target: <0.2%

Formula: `(hedge_word_count / total_word_count) * 100`

| Score | Rating | Action |
|-------|--------|--------|
| <0.1% | Excellent | Maintain |
| 0.1-0.2% | Good | Minor tweaks optional |
| 0.2-0.5% | Fair | Review and reduce |
| >0.5% | Poor | Significant rewrite needed |

### Hedge Words to Eliminate

**High impact:** maybe, possibly, perhaps, might, could be
**Medium impact:** however, although, it seems, arguably, potentially
**Cumulative:** some believe, it appears, in my opinion, to some extent

### Remediation Strategies

| Strategy | Before | After |
|----------|--------|-------|
| **Direct replacement** | "This might improve performance" | "This improves performance by 40% in benchmarks" |
| **Quantify claims** | "Some users find this helpful" | "72% of surveyed users report improved productivity" |
| **Cite sources** | "It seems caching improves times" | "Caching improves response times by 60% (Redis benchmarks, 2024)" |
| **Conditional precision** | "This might work for your use case" | "This works for apps with <1000 concurrent users" |
| **Remove qualifiers** | "In my opinion, React is arguably good" | "React is a strong choice for component-based UIs" |

### When Hedging is Appropriate
- Genuine scientific uncertainty: "Studies suggest a correlation (p<0.05)"
- Legal disclaimers: "This is not financial advice"
- Preliminary findings: "Early results indicate..."
- Clearly labeled speculation sections

## HTML Size Budget

**Hard limit:** 1MB raw HTML. Above this, 18% of pages are abandoned by crawlers.

| Component | Max Budget |
|-----------|------------|
| Core content | 500KB |
| Navigation/UI | 200KB |
| Inline CSS | 100KB |
| Inline JS | 100KB |
| Metadata | 50KB |
| Buffer | 50KB |

### Reducing HTML Size
1. Remove inline SVGs — link instead
2. Defer non-critical CSS
3. Strip HTML comments in production
4. Minify HTML
5. Lazy load below-fold content
6. Externalize scripts

## JavaScript Dependency Risk

~40% of AI crawlers don't render JavaScript.

| Crawler | Renders JS |
|---------|------------|
| GPTBot | Yes |
| ClaudeBot | No |
| PerplexityBot | Sometimes |
| Google-Extended | Yes |
| Anthropic-AI | No |

### JS Dependency Score

| Score | Risk | Action |
|-------|------|--------|
| <10% | Low | Content mostly visible |
| 10-30% | Medium | Audit critical content |
| 30-50% | High | Implement SSR/SSG |
| >50% | Critical | Architecture change needed |

### Mitigation
- **SSR:** Next.js `getServerSideProps`, Nuxt (default), SvelteKit (default)
- **SSG:** Next.js `getStaticProps`, Astro (default), 11ty (default)
- **Hybrid:** Static shell + hydration, progressive enhancement
- **Prerendering:** Prerender.io, Rendertron for SPAs that can't be refactored

## Discovery Gap

Startups face a 30:1 visibility disadvantage in AI search:

| Site Age | AI Visibility | Strategy |
|----------|--------------|----------|
| <6 months | ~1% | Web-augmented signals only |
| 6-24 months | ~3.3% | Hybrid: web signals + basic GEO |
| 2-5 years | ~60% | Full GEO optimization |
| 5+ years | ~99% | Maintain and defend position |

### Strategy by Age

**New sites (<2 years):** Focus on web-augmented signals
- Build Reddit presence in relevant subreddits
- Earn referring domains via guest posts, HARO
- Accumulate social proof (Twitter/X, LinkedIn mentions)
- Implement basic AgentFacts for future-proofing

**Established sites (2+ years):** Full GEO optimization
- Comprehensive hedge density audit
- Technical visibility optimization
- Entity density improvement
- Content refresh with confident language

## AgentFacts / NANDA Protocol

Machine-readable metadata for AI agent discovery. Place at `/.well-known/agent-facts`.

### Minimal Valid Schema
```json
{
  "@context": "https://nanda.dev/ns/agent-facts/v1",
  "id": "nanda:yourdomain.com",
  "agent_name": "Your Service Name"
}
```

### Full Schema Fields
- `@context` (required): NANDA namespace URI
- `id` (required): Format `nanda:domain.com`
- `agent_name` (required): URN or human-readable name
- `endpoints`: Static URLs and adaptive resolvers
- `capabilities`: Modalities, operations, authentication, rate limits
- `trust`: Certification level, human oversight, audit log
- `contact`: Support and abuse email
- `metadata`: Created/modified dates, TTL for caching

### Serving AgentFacts
- Content-Type: `application/ld+json`
- CORS: `Access-Control-Allow-Origin: *`
- Cache: `Cache-Control: public, max-age=86400`

## Technical Visibility Audit Checklist

- [ ] HTML size under 1MB
- [ ] Critical content visible without JavaScript
- [ ] Content-to-code ratio >15%
- [ ] TTFB under 500ms
- [ ] Mobile rendering works correctly
- [ ] robots.txt allows AI crawlers (GPTBot, ClaudeBot, PerplexityBot)
- [ ] No infinite scroll without pagination fallback
- [ ] Core content in initial HTML response
- [ ] AgentFacts at `/.well-known/agent-facts`
- [ ] Hedge density <0.2% on key pages

## Content Authority Signals

For AI citations, strengthen these:
- **Entity density:** Named entities, specific data points, dates
- **Confidence language:** Declarative statements backed by evidence
- **Structured data:** Schema markup, clear HTML semantics
- **Source attribution:** Citations, links to primary sources
- **Recency signals:** Updated dates, current references
