# UX Copy Patterns

Patterns and guidelines for writing interface text that helps users accomplish their goals.

## Four Quality Standards

Every piece of UX text must be:

1. **Purposeful** — Helps users or the business achieve goals
2. **Concise** — Fewest words possible without losing meaning
3. **Conversational** — Sounds natural and human, not robotic
4. **Clear** — Unambiguous, accurate, easy to understand

## Text Patterns by Element

### Titles
- **Format:** Noun phrases, sentence case
- **Types:** Brand titles, content titles, category titles, task titles
- **Examples:** "Account settings", "Your library", "Create new post"

### Buttons and Links
- **Format:** Active imperative verbs, sentence case
- **Pattern:** `[Verb] [object]`
- **Good:** "Save changes", "Delete account", "View details"
- **Avoid:** Generic labels — "OK", "Submit", "Click here"

### Error Messages

**Pattern:** `[What failed]. [Why/context]. [What to do].`

**Types:**

| Type | When | Pattern | Example |
|------|------|---------|---------|
| **Validation** (inline) | User completes field | `[Field] [requirement]` | "Email must include @" |
| **System** (banner/modal) | Backend failure | `[Action failed]. [Cause]. [Recovery].` | "Payment failed. Card declined. Try a different method." |
| **Blocking** (full-screen) | Can't continue | `[What's blocked]. [Why]. [Action needed].` | "Update required. This version is no longer supported. Update now." |
| **Permission** | Feature first use | `[User benefit]. [Permission needed].` | "Get notified when orders ship. Enable notifications." |

**Timing:**
- Validation: real-time or on field exit, below the field
- System: immediately after failure, banner or modal
- Blocking: on app launch or feature access, full screen
- Permission: when feature first used, in context

**Never do:**
- Technical codes without explanation ("Error 403")
- Blame language ("invalid input", "illegal character")
- Robotic tone ("An error has occurred")
- Dead ends (error with no recovery path)
- Vague causes ("Something went wrong")

### Success Messages
- **Format:** Past tense, specific
- **Pattern:** `[Action] [result/benefit]`
- **Examples:** "Changes saved", "Email sent", "Profile updated"
- Keep proportional to the action — don't celebrate a settings toggle.

### Empty States
- **Types:** First-use, user-cleared, error/no results
- **Pattern:** Explanation + CTA
- **First-use:** "No messages yet. Start a conversation to connect with your team."
- **User-cleared:** "All caught up! You've read all your notifications."
- **No results:** "No results for 'xyz'. Try different keywords or check spelling."

### Form Fields
- **Labels:** Clear noun phrases — "Email address", "Phone number"
- **Instructions:** Verb-first, explain why info is needed when non-obvious
- **Placeholder:** Sparingly, only standard formats — "name@example.com"
- **Helper text:** Below field, for important constraints — "Must be at least 8 characters"

### Notifications
- **Types:** Action-required (intrusive) vs passive (less intrusive)
- **Format:** Verb-first title + contextual description
- **Example:** "Update required. Install the latest version to continue."

## Tone Adaptation

Voice is constant; tone shifts by context.

### By Emotional State

| State | Approach | Example |
|-------|----------|---------|
| **Frustrated** | Empathetic, solution-focused, no blame | "Payment failed. Card declined. Try a different method." |
| **Confused** | Patient, explanatory, step-by-step | "Connect your bank to see spending insights. We'll guide you through it." |
| **Confident** | Efficient, direct, minimal | "Saved" |
| **Cautious** | Serious, transparent, clear consequences | "Delete account? You'll lose all data. This can't be undone." |
| **Successful** | Positive, proportional, brief | "Profile updated. Your changes are live." |

### By Content Type

| Type | Tone | Key Rule |
|------|------|----------|
| Errors | Empathetic, reassuring | Never blame user |
| Success | Positive, specific | Proportional to action |
| Instructions | Clear, direct | Front-load key action |
| Onboarding | Inviting, concise | Focus on value |
| Confirmations | Serious, transparent | Easy to back out |
| Empty states | Hopeful, actionable | Provide clear next step |

## Accessibility

### Screen Reader Optimization
- Label all interactive elements explicitly: "Submit application" not just "Submit"
- Descriptive link text: "Read pricing details" not "Click here"
- Error messages must work read aloud: error + field label together
- Use ARIA labels when visual context is insufficient

### Cognitive Accessibility
- 8 words = 100% comprehension; 14 words = 90%; 25 words = significant drop
- Break complex info into scannable chunks
- Clear headings, logical hierarchy
- Consistent, predictable patterns

### Multi-Modal Communication
- Don't rely on color alone — pair with text/icons
- Provide text alternatives for icons and images
- Minimum color contrast: 4.5:1 (WCAG AA)

### Plain Language
- General audience: 7th-8th grade reading level
- Professional tools: 9th-10th grade
- Define technical terms on first use
- Avoid idioms, metaphors, cultural references

## Benchmarks

### Sentence Length
- **Buttons/CTAs:** 2-4 words, max 6
- **Titles:** 3-6 words, max 40 characters
- **Error messages:** 12-18 words including solution
- **Instructions:** max 20 words, ideal 14
- **Body copy:** 15-20 words per sentence
- **Notifications:** 10-15 words for title + body

### Character Limits
- **Line length:** 40-60 characters for readability
- **Button labels:** 15-25 characters
- **Page titles:** 30-50 characters
- **Notification titles:** 35-45 characters

## Quick Reference

- **Sentence case:** "Save your changes" not "Save Your Changes"
- **Active imperative for buttons:** "Delete account" not "Account deletion"
- **User-focused:** "Save time with shortcuts" not "We offer shortcuts"
- **Specific verbs:** "Delete" not "Remove" when permanently deleting
- **Front-loaded:** "Password must be 8 characters" not "Must be 8 characters for your password"
