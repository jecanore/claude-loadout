# AI Writing Patterns to Avoid

LLMs regress to statistical means, producing generic, puffy prose. This guide helps detect and eliminate these patterns. Based on field-tested detection criteria developed by Wikipedia editors.

## Why AI Writing Sounds Generic

LLMs predict the most probable next token. This creates:
- **Mean regression:** Writing converges to average internet prose
- **Hedging:** Models add qualifiers to seem balanced
- **Filler:** Padding to meet implicit length expectations
- **Grandiosity:** Inflated language to seem authoritative

## Puffery Words

These words signal empty emphasis. Replace with specific claims or cut entirely.

**Cut these:** pivotal, crucial, vital, testament, enduring legacy, remarkable, notable, significant, profound, impressive, extraordinary, invaluable, indispensable, quintessential, seminal, transformative

**Instead:** State the specific impact. "Reduced build times by 40%" beats "a transformative improvement."

## Empty "-ing" Phrases

Gerund phrases that say nothing:
- ensuring reliability → (delete or state how)
- showcasing features → (state which features and why)
- highlighting capabilities → (state the capability)
- demonstrating commitment → (state the action)
- fostering innovation → (state what was created)
- driving engagement → (state the metric)
- leveraging technology → (state the technology and its use)

## Promotional Adjectives

Adjectives that inflate without informing:
- groundbreaking, seamless, robust, cutting-edge
- innovative, state-of-the-art, next-generation
- world-class, best-in-class, industry-leading
- comprehensive, holistic, synergistic

**Instead:** Use factual descriptors. "Handles 10K requests/sec" beats "a robust, high-performance solution."

## Overused AI Vocabulary

Words that appear 3-10x more frequently in AI text than human text:

| AI Default | Human Alternative |
|---|---|
| delve | examine, explore, look at |
| leverage | use |
| multifaceted | complex, varied |
| foster | encourage, support, build |
| realm | area, field, domain |
| tapestry | mix, combination |
| landscape | field, market, area |
| paradigm | model, approach |
| nuanced | detailed, subtle |
| underscores | shows, highlights |
| arguably | (cut — just make the argument) |
| It's important to note | (cut — just state it) |
| It's worth noting | (cut — just state it) |
| In today's [X] landscape | (cut — rewrite) |

## Structural Tells

### Excessive Formatting
- Bullet points for everything (even flowing narrative)
- Bold on every other phrase
- Emoji as section markers in technical writing
- Headers for 2-sentence sections

### The "Triple Pattern"
AI loves groups of three adjectives/items where two would suffice:
- "clear, concise, and comprehensive"
- "fast, reliable, and scalable"

### Sycophantic Openers
- "Great question!"
- "That's a really interesting point."
- "Absolutely!"

### Summarizing What Was Just Said
- "In summary, ..."
- "To recap, ..."
- "As we've discussed, ..."
(Cut these unless writing is genuinely long enough to need a summary.)

### The "Not Only... But Also" Pattern
Overused rhetorical escalation. Usually one clause is enough.

## The Fix: Specificity

Every AI pattern has the same root cause: vagueness masquerading as substance.

The fix is always the same: **be specific.**

| AI Pattern | Specific Alternative |
|---|---|
| "a groundbreaking new approach" | "uses AST-based analysis instead of regex" |
| "ensuring seamless integration" | "installs with one npm command, zero config" |
| "fostering a culture of innovation" | "engineers get 20% time for side projects" |
| "leveraging cutting-edge technology" | "built on WebGPU for GPU-accelerated rendering" |
| "a testament to our commitment" | "we shipped 47 patches in 30 days" |

## Self-Check Process

After writing, scan for:
1. **Any word from the puffery list** — replace or cut
2. **Adjectives without evidence** — add specifics or cut
3. **"-ing" phrases that could be deleted** — delete them
4. **Groups of three** where two suffice — trim
5. **Sentences that could start with "It's worth noting"** — they don't need it
6. **Any claim without a number, name, or example** — add one or soften honestly
