# Explainer Template

Quick-mode template for `/academy explain <filepath>`. Produces a focused walkthrough of a single file.

---

## Template

```markdown
# Understanding `<filename>`

> **What this file does:** <one-sentence summary>
> **Difficulty:** Beginner | Intermediate | Advanced
> **Tech Stack:** <technologies used in this file>

## Why This File Exists

<2-3 sentences on what problem this file solves and where it fits in the project architecture.>

## Key Vocabulary

| Term | Definition |
|------|-----------|
| <term> | <plain-English definition> |

## The Code — Annotated

```<language>
// <filepath>
<full file contents>
```

**Section-by-section breakdown:**

### Lines X-Y: <section purpose>

<Explain what this block does, why it's structured this way, and any patterns it uses.>

<!-- Repeat for each logical section of the file -->

## How This File Connects

| Relationship | File(s) |
|-------------|---------|
| **Imports from** | <files this depends on> |
| **Exported to** | <files that import from this> |
| **Called by** | <entry points or callers> |

## Prompting Tips

When asking Claude Code to modify this file:
- <precise vocabulary tip>
- <what to specify in prompts>
- <common mistakes to avoid>
```
