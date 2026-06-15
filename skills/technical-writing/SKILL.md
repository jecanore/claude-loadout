---
name: technical-writing
description: >
  Use when writing prose humans will read in a technical context —
  documentation, README files, commit messages, PR descriptions,
  error messages, UI copy, help text, code comments, reports, or summaries.
  Applies Elements of Style rules, UX writing patterns, and documentation standards.
type: flexible
version: 0.2.0
---

# Technical Writing

Write clear, concise, professional prose for technical contexts. This skill merges Elements of Style composition principles, UX writing patterns, and documentation standards into one coherent guide.

> **Announce at start (every invocation):** "Using technical-writing to revise {target}." Then state which reference file you're loading (if any) before applying its rules.

## When to Use

- Documentation, README files, technical explanations
- Commit messages, pull request descriptions
- Error messages, UI copy, help text
- Code comments, inline docs, API docs
- Reports, summaries, changelogs, ADRs
- Any prose a human reads in a code/product context

## Limited Context Strategy

This SKILL.md contains summary rules (~3K tokens). Detailed guidance lives in `references/`. When you need specifics:

1. Write your draft using the summary rules below
2. Load only the relevant reference file
3. Apply its guidance to revise

Loading one reference (~1.5-3K tokens) instead of everything saves significant context.

## Core Composition Rules

From Strunk's *Elements of Style* — the six rules that matter most:

1. **Use active voice.** "Dead leaves covered the ground" not "There were dead leaves lying on the ground."
2. **Put statements in positive form.** "He usually came late" not "He was not very often on time."
3. **Use definite, specific, concrete language.** "It rained every day for a week" not "A period of unfavorable weather set in."
4. **Omit needless words.** Every word must earn its place. Cut "the fact that", "the question as to whether", "he is a man who".
5. **Keep related words together.** Don't separate subject and verb with long parenthetical clauses.
6. **Place emphatic words at end of sentence.** The end position gets the most weight.

Supporting rules: one paragraph per topic, topic sentence first, parallel structure for coordinate ideas, consistent tense in summaries.

See `references/elements-of-style.md` for complete rules with examples.

## AI Patterns to Avoid

LLMs regress to generic, puffy prose. Watch for:

- **Puffery:** pivotal, crucial, vital, testament, enduring legacy
- **Empty "-ing" phrases:** ensuring reliability, showcasing features, highlighting capabilities
- **Promotional adjectives:** groundbreaking, seamless, robust, cutting-edge
- **Overused AI vocabulary:** delve, leverage, multifaceted, foster, realm, tapestry
- **Formatting overuse:** excessive bullets, emoji decorations, bold on every other word

Be specific, not grandiose. Say what it actually does.

See `references/ai-patterns-to-avoid.md` for the full detection list.

## UX Copy Quick Reference

For interface text (buttons, errors, empty states, notifications):

- **Four standards:** Purposeful, Concise, Conversational, Clear
- **Buttons:** `[Verb] [object]` in sentence case — "Save changes", "Delete account"
- **Errors:** `[What failed]. [Why/context]. [What to do].` — "Payment failed. Card declined. Try a different method."
- **Empty states:** Explanation + CTA — "No messages yet. Start a conversation."
- **Accessibility:** Label all interactive elements, 8-14 words per sentence, don't rely on color alone

See `references/ux-copy-patterns.md` for all patterns, tone adaptation, and benchmarks.

## Documentation Quick Reference

- **Comments:** Explain *why*, not *what*. If you need to explain what, refactor the code first.
- **README:** What (1 sentence) + Why (problem) + Quick Start + Setup
- **ADRs:** Context → Decision → Consequences
- **Maintenance:** Update docs for breaking changes. Stale docs are worse than no docs.

See `references/documentation-standards.md` for full guidelines.

## Commit & PR Quick Reference

- **Commits:** Imperative mood, explain why not what, 50-char subject / 72-char body wrap
- **PRs:** Summary (1-3 bullets) + Test Plan (checklist) + link related issues

See `references/commit-and-pr-writing.md` for patterns and examples.

## Reference Files

| When You Need | File | ~Tokens |
|---------------|------|---------|
| Composition principles, active voice, concision | `elements-of-style.md` | 3,000 |
| AI writing detection and avoidance | `ai-patterns-to-avoid.md` | 1,500 |
| UX copy: errors, buttons, forms, empty states, tone | `ux-copy-patterns.md` | 3,000 |
| Comments, README, ADRs, CHANGELOG, maintenance | `documentation-standards.md` | 3,000 |
| Commit messages, PR descriptions | `commit-and-pr-writing.md` | 1,500 |

## Editing Checklist

Run every piece of writing through these four phases:

1. **Purposeful** — Does it help the reader? Is the value clear?
2. **Concise** — Can any word be cut? Is important info front-loaded?
3. **Conversational** — Read it aloud. Would you say this to a colleague?
4. **Clear** — Is it unambiguous? Are verbs specific? Is terminology consistent?

## Readability Targets

| Content Type | Words | Characters | Reading Level |
|--------------|-------|------------|---------------|
| Buttons/CTAs | 2-4 | 15-25 | — |
| Error messages | 12-18 | — | 7th grade |
| Instructions | 14-20 | — | 8th grade |
| Body copy | 15-20/sentence | 40-60/line | 8th-10th grade |
| Commit subjects | — | 50 max | — |
| PR titles | — | 70 max | — |
| Meta descriptions | — | 160 max | — |

## Red Flags

These thoughts mean STOP. You are rationalizing.

- "This is a quick note, the rules don't apply here." — They apply more, not less. Short prose has nowhere to hide weak word choice.
- "I'll write the long version first and trim later." — Trimming rarely happens. Cut as you draft.
- "Bullets make it scannable, so more bullets is better." — Bullets fragment connected reasoning. Use prose for arguments, bullets for parallel items.
- "The reader will infer what I mean." — They won't. Specific, concrete, unambiguous, every time.
- "I already revised this once, the editing checklist is overkill." — One pass catches typos. Four passes (Purposeful / Concise / Conversational / Clear) catch structure.
- "This is internal copy, the AI-pattern detector doesn't matter." — Puffery and empty "-ing" phrases regress on every draft. Detect and remove regardless of audience.
- "I'll skip loading the reference — I remember the rules." — Memory drifts. Load the reference when the work is non-trivial.
- "An emoji or two adds personality." — In technical prose it adds noise. Reserve for UI copy where tone is part of the contract.

## Rationalization Defense

| Excuse | Reality |
|---|---|
| "Active voice sounds aggressive here." | Passive voice hides the actor. If you're hiding the actor on purpose, say why; otherwise rewrite. |
| "The negative form reads more carefully." | Positive form reads faster and lands harder. "He usually came late" beats "He was not very often on time." |
| "Specific examples make the doc longer." | They make it usable. Generic prose is shorter and unhelpful. |
| "These filler words add rhythm." | They add length. Cut "the fact that," "in order to," "really," "very." Rhythm survives concision. |
| "I'll keep 'leverage' / 'delve' / 'robust' — everyone uses them." | Everyone uses them because LLMs do. Replace with the concrete verb you mean. |
| "Comments that explain *what* are still useful documentation." | They duplicate the code and rot first. Comment the *why*; refactor the code if the *what* is unclear. |
| "This commit subject is 65 chars — close enough." | 50 chars is the limit because git tooling truncates. Rewrite. |
| "Empty states are decorative; the explanation is enough." | Empty state without a CTA leaves the user stuck. Always pair explanation + next action. |

## Provides

- Editing checklist (Purposeful / Concise / Conversational / Clear) usable as a four-phase review pass.
- Readability targets table with concrete word/character/grade-level limits per content type.
- AI-pattern detection list for automated and manual review of generated prose.
- Reference taxonomy (`elements-of-style`, `ai-patterns-to-avoid`, `ux-copy-patterns`, `documentation-standards`, `commit-and-pr-writing`) other skills can cite by name.

## Consumes

- No required dependencies.
- Optional: `ux-copy` skill — when the target is interface microcopy specifically; this skill defers to ux-copy for tone, voice, and CTA naming.
- Optional: reference files in `references/` — loaded progressively; see the Reference Files table above.
