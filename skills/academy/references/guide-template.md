# Guide Template

This template defines the standard structure for every Academy guide. Each part is required unless explicitly marked optional. Adapt section depth to the topic — a simple concept might have shorter parts, but the structure stays the same.

> **`{project}`** in this template = the project name from SKILL.md's Project Resolution step. Replace with the actual name in all generated output.

---

## Template

```markdown
# <Topic> — The Complete Guide

> <One-line summary of what this guide teaches>. No prior knowledge assumed.
>
> **Difficulty:** Beginner | Intermediate | Advanced
> **Tech Stack Mastery:** <comma-separated list of specific technologies covered>

---

## Part 1: The Concepts

### What Problem Does This Solve?

<2-3 paragraphs explaining the pain point this concept addresses. Use a concrete scenario — ideally one relevant to {project}.>

### Key Vocabulary

| Term | Plain-English Definition |
|------|------------------------|
| <term> | <definition a non-developer could understand> |
| ... | ... |

### The Core Ideas

<Explain the fundamental concepts in plain English. No code yet. Use analogies where they help. Each concept gets its own subsection if complex enough.>

---

## Part 2: How It Works

<Step-by-step explanation of the mechanism. Walk through the flow from start to finish.>

<Include ASCII diagrams where they clarify flow or architecture:>

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│  Step 1  │───>│  Step 2  │───>│  Step 3  │
└─────────┘    └─────────┘    └─────────┘
```

<Break complex flows into numbered steps with explanations between each.>

---

## Part 3: Your Actual Code — Annotated

### `<filename>` — <what this file does>

<Brief context for why this file matters to the topic.>

```<language>
// <filepath>
<code from the actual {project} codebase>
```

**Line-by-line breakdown:**

1. **Line X:** <what this line does and why>
2. **Line Y:** <what this line does and why>
3. ...

<Repeat for each relevant file. Group related files under subheadings.>

---

## Part 4: Common Patterns

### Pattern: <Name>

**What it is:** <one-sentence definition>

**When to use it:** <the scenario where this pattern applies>

**Example:**

```<language>
<code example — from {project} if possible, otherwise clearly marked as illustrative>
```

<Repeat for each pattern. 3-5 patterns is typical.>

---

## Part 5: Prompting AI Agents

### Key Vocabulary for Prompts

<List the terms from this guide that produce better AI agent results when used precisely. Show "vague prompt" vs "precise prompt" comparisons.>

### Example Prompts That Work

<3-5 example prompts a technical co-founder could give Claude Code, using the vocabulary and patterns from this guide. Each prompt should reference real files or patterns.>

### What to Check in AI-Generated Code

<Checklist of things to verify when an AI agent generates code related to this topic. Based on the patterns and rules taught in this guide.>

### Common Mistakes AI Agents Make

<2-3 mistakes AI agents commonly make in this area, and how to catch them. These should be specific to the topic, not generic.>

---

## Part 6: Hands-On Reference

### Commands Cheat Sheet

| Command | What It Does |
|---------|-------------|
| `<command>` | <plain-English description> |
| ... | ... |

### Quick-Reference Table

| Concept | One-Liner |
|---------|-----------|
| <concept> | <shortest useful definition> |
| ... | ... |

<Include API references, configuration keys, or syntax tables as appropriate to the topic.>

---

## Part 7: Opportunities for {project}

### <Opportunity 1>

**What:** <what could be added or improved>
**Why:** <the benefit to the project or team>
**Complexity:** <Low / Medium / High>

<Repeat for 2-4 realistic opportunities. These should be actionable, not aspirational.>

---

## Part 8: Troubleshooting

### "<Error message or symptom>"

**Cause:** <why this happens>
**Fix:** <step-by-step solution>

<Repeat for 3-5 common mistakes. Include actual error messages when possible.>

---

## Part 9: Summary

Every concept from this guide in one table:

| Concept | One-Sentence Definition |
|---------|------------------------|
| <concept> | <definition> |
| ... | ... |

### What's Next

<2-3 suggested next topics that build on this guide. Link to existing guides if they exist.>
```

---

## 101 Template (Condensed)

101 guides (topics ending in `-101`) use a condensed format. They cover breadth — vocabulary, real examples, and prompting tips — not depth. Use this structure instead of the full template:

```markdown
# <Topic> 101 — The Essential Guide

> <One-line summary>. No prior knowledge assumed.
>
> **Tech Stack Mastery:** <comma-separated list of specific technologies covered>

---

## Part 1: The Concepts

### What Problem Does This Solve?

<Same as full template>

### Key Vocabulary

<Same as full template — this is especially important for 101 guides>

### The Core Ideas

<Same as full template, but cover more concepts at less depth>

---

## Part 2: How It Works

<Condensed — focus on the mental model, not exhaustive detail>

---

## Part 3: Your Actual Code — Annotated

<Same as full template — real {project} snippets with line-by-line breakdowns. This is still the heart of the guide. Cover more files with shorter excerpts.>

---

## Part 4: Prompting AI Agents

<Same content as Part 5 in the full template — vocabulary for prompts, example prompts, what to check, common AI mistakes.>

---

## Part 5: Summary

Every concept from this guide in one table:

| Concept | One-Sentence Definition |
|---------|------------------------|
| <concept> | <definition> |
| ... | ... |

### What's Next

<2-3 suggested next topics that build on this guide.>
```

---

## Template Notes

- **Part 3 is the heart of the guide.** Spend the most effort here — real code with real explanations.
- **ASCII diagrams** are preferred over descriptions of flow. A picture is worth a paragraph.
- **Vocabulary tables** appear in Part 1 (definitions) and Part 9 (summary). Part 1 is for learning; Part 9 is for quick lookup.
- **Prompting AI Agents (Part 5)** bridges knowledge into action. The reader should finish able to describe what they want to an AI agent using precise vocabulary.
- **Opportunities (Part 7)** make the guide actionable. The reader should finish thinking "I could do this."
- **Troubleshooting (Part 8)** prevents frustration. Include the mistakes you'd make learning this topic for the first time.
- **101 guides** skip Common Patterns, Hands-On Reference, Opportunities, and Troubleshooting to stay focused on literacy. They still require real code examples and the Prompting section.
