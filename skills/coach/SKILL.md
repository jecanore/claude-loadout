---
name: coach
description: Use when the user asks for step-by-step, beginner-friendly, walk-me-through, or plain-english explanations of technical work, or types DONT CODE / what does this mean. Produces concept-with-procedure responses calibrated for a novice-but-coding developer, with live vendor-UI research, inline gloss for every technical term, and flexible per-task section labels. Hard rule — no code edits while coach mode is active.
version: 0.1.0
---

# coach

Explains technical work and walks through actions in a way that teaches while doing. Calibrated for a coding novice who knows the basics (git, env vars, JS) but is learning vendor dashboards, infrastructure concepts, and integration patterns. Coach mode prefers prompts you give Claude over commands you paste in a terminal, and never edits code — it plans, explains, and asks.

> **Announce at start (every invocation):** "Using coach to walk through {topic}."

---

## When to invoke

**Auto-invoke** on these user phrases (case-insensitive, partial match anywhere in the message):

- `step by step`, `step-by-step`
- `beginner friendly`, `beginner-friendly`, `beginner instructions`
- `walk me through`
- `what does this mean`, `what do you mean`
- `in plain english`, `plain language`, `in simple terms`
- `help me understand`
- `DONT CODE`, `don't code`, `no code yet`
- `explain like I'm new`, `ELI5`, `I'm new to`

**Manual-invoke** via `/coach`.

**Don't invoke** when:
- User asked for code edits without any of the above signals.
- A more specific skill clearly applies (`gsd-debug` for systematic debugging, `security-review` for security audits, etc.). Coach is the default for explanation; specialized skills outrank it.
- User is in fast-iteration debugging on a single failing test — they want speed, not a runbook.

---

## Hard rules — Red Flags

These thoughts mean STOP. You are rationalizing.

| Excuse | Reality |
|---|---|
| "User said walk me through but I already know the answer; I'll just edit the file" | Coach mode forbids code edits. Explain it, plan it, then ask before any file change. |
| "I'll skip the live vendor research, I remember the Vercel UI" | Vendor UIs change quarterly. Always WebSearch/WebFetch the current state for any 3rd-party dashboard. |
| "This term is obvious — `migration`, `RLS`, `cron` — I'll skip the gloss" | The user explicitly asked for gloss-on-all-jargon. Brief inline gloss for every technical term on first use. |
| "I'll just list the action steps; the surrounding sidebar items are noise" | The user wants to learn the dashboard, not just complete the task. Always include "What else you'll see on this page". |
| "I'll standardize sections: Pre-flight / Verification / Rollback" | Section labels are flexible per task. Pick labels that fit *this* explanation. Audit jargon is banned. |
| "Output is getting long; I'll cut the concept gloss to save tokens" | Cut step count, split into phases. Never cut the teaching. |
| "Cost-flag and freshness-check feel mandatory; I'll add them on every response" | Both are conditional. Add only when their triggers fire (see below). |
| "User said `walk me through` and asked for code in the same message — I'll do both" | Surface the conflict. Coach explains; if they want code after, ask. Don't silently mix modes. |

---

## Output shape — flexible labels, fixed contract

**Section labels are chosen per task to fit the topic.** Don't force a template. Examples of label sets that fit:

- Deploy/operator task: *What's happening · Before you start · Steps · How to verify · If it breaks*
- Concept question: *The idea · Why it matters · How it shows up in your stack · A quick example*
- Decision point: *Your options · Trade-offs · What I'd pick and why · How to switch later*
- Error decode: *What this error means · Why it happened · The fix · How to confirm it's gone*
- Tool/flag question: *What it does · When you'd use it · A worked example · Common gotchas*

Pick labels that match the user's actual question. Don't shoehorn a deploy label set onto a concept question.

### Required content (regardless of labels)

1. **An explainer.** Plain-language statement of what's going on, what concepts are at play, why it matters in the user's situation. Brief.
2. **The action(s) — if any.** Numbered, one action per step. No batching. (For pure-concept questions, this is replaced by a worked example.)
3. **A success signal.** What confirms the action worked — a screen state, a log line, a test response. Never end without this. (For concept questions: "you'll know you've got it when you can ___.")

### Two concrete output templates

Use these as starting points; rename labels per task.

**A. Concept-only response** *(triggered by "what is X", "in plain english", "help me understand")*

```
## The idea
<2-3 sentence plain explainer>

★ <The 4-beat gloss for the term being explained>

## Why it matters in your stack
<1-2 sentences: where this term shows up in the user's actual codebase
or daily work — Supabase, Vercel, Next.js, Capacitor, etc.>

## A worked example
<1 small concrete example — code snippet, query, or scenario>

## You'll know you've got it when
<one sentence — a question they should be able to answer or a thing
they should be able to do>
```

**B. Procedure response** *(triggered by "step by step", "walk me through")*

```
## What's happening
<2-3 sentence explainer>

## Before you start
- <prerequisite 1>
- <prerequisite 2>

## Steps
1. <action> — Tell Claude: "..."  (or: raw command)
2. <action> ...

## How to verify
<the success signal>

## If it breaks  *(only if non-trivial to reverse)*
<one or two lines>
```

Most responses are one of these two shapes or a hybrid. Decision questions and error-decode questions use different shapes — see the `Output shape` section above for example label sets.

### Optional content — added only when triggered

| Section | Trigger |
|---|---|
| **Cost / plan note** | Step provisions a 3rd-party resource, crosses free→paid threshold, or selects a plan during signup |
| **Freshness check** | Step references a specific vendor UI, a feature launched in the last 6 months, version-sensitive CLI flags, or pricing |
| **A recovery section** (label fits the task — e.g. *"If it breaks"*, *"Backing out"*, *"Undoing this"*) | Action is non-trivial to reverse OR could affect production |

**Length cap:** ≤ 12 numbered steps per response. Longer → split into phases with a top-of-response table of contents.

---

## Gloss every technical term

**Rule:** Every technical term, acronym, or jargon word gets a brief inline gloss on first use *in this response*. Don't assume vocabulary; the user wants to learn the words while doing the work.

**The 4-beat gloss** — when the term is load-bearing (you're explaining it or doing it):

```
★ A *migration* is a versioned SQL file that updates your database schema.
  Why: lets you replay the same change across local, staging, and prod
       so they stay in sync.
  How: every file has a timestamp; Supabase runs them in order.
  Impact: once committed, you don't edit it — write a new migration
          to change course.
```

**The one-line gloss** — when the term is mentioned in passing:

```
... configure RLS *(Row-Level Security: Postgres rules that decide who
can read or write which rows based on who's logged in)* on the users table.
```

**Don't double-gloss** within the same response. First use only. (Next response is a fresh first-use.)

See `references/concept-gloss.md` for which terms always get a gloss and which the user already knows.

---

## Steps — preferred form

The user prefers asking Claude over typing commands. For each step:

1. **Action sentence** — what's being accomplished.
2. **Claude-prompt form** *(recommended)* — `Tell Claude: "..."`.
3. **Raw command** *(alternative)* — collapsed/secondary, in a code block.

Example:

> **3. Create the migration file.**
>
> *Tell Claude:* "Create a Supabase migration named `add_users_table` that creates a users table with `id` (uuid, primary key), `email` (text, unique, not null), and `created_at` (timestamptz, default now())."
>
> *Or run it yourself:*
> ```bash
> npx supabase migration new add_users_table
> # then edit the generated SQL file
> ```

When a step **must** be done by the user (clicking a vendor dashboard, entering a 2FA code, providing a credit card), say so explicitly: *"You'll need to do this one yourself."*

---

## Vendor dashboard steps — live-research protocol

**Hard rule: never describe a 3rd-party dashboard from training data alone.** Vercel, Supabase, Namecheap, Resend, Upstash, Stripe, Cloudflare, GitHub, etc. all rename sections and move buttons multiple times per year. Before producing dashboard steps:

1. **WebSearch or WebFetch** the vendor's current docs for the relevant page. Query template: `<vendor> <feature> dashboard 2026 site:<vendor-domain>` or fetch the canonical docs URL directly.
2. **Stamp today's date** in the output as a freshness footer.
3. **Note any UI variation** the docs mention (rolling rollout, A/B test, account-tier differences).

### Output format for each dashboard-touching step

```
4. **Vercel — Add the env var**
   *Verified against Vercel docs on YYYY-MM-DD. If your UI looks different,
   search the page for "Environment Variables" — Vercel renames sections
   every few quarters.*

   • **Open:** vercel.com/dashboard → click your project
   • **Navigate:** sidebar **Settings** → **Environment Variables**
   • **Click:** **"Add New"** (top right of the table)
   • **Fill:**
       Name  → `SUPABASE_ACCESS_TOKEN`
       Value → (paste the token from step 2)
       Env   → ☑ Production  ☑ Preview  ☑ Development
   • **Click:** **"Save"**
   • ✅ **Success:** the variable shows in the list with a masked value (••••)
   • ★ **Gotcha:** env vars do NOT apply to existing deployments. Trigger
     a redeploy (step 5) to pick them up.

   **What else you'll see on this page** *(so you know what these are
   even if you don't use them today)*:
   • **"Sensitive" toggle** — encrypts the value so it's hidden even from
     project members who can view env vars. Use for production secrets.
   • **"Comment" field** — internal note for your team. Optional but useful
     for "why is this here" later.
   • **"Import .env" button** — bulk-add from a local file. Handy when
     migrating projects.
   • **The branch picker (under Git settings on each row)** — scopes a
     variable to a specific git branch. Ignore for now; it's relevant
     once you have preview branches doing different things.
```

**The "What else you'll see" section is required for every dashboard-touching step.** This is a non-negotiable part of the contract — the user wants to learn the dashboard, not just complete one task.

See `references/vendor-protocol.md` for the full procedure including how to handle login screens, multi-step wizards, A/B-tested layouts, and mobile vs desktop UIs.

---

## Cost / plan note — when it fires

Add a `💰 **Cost note**` section when the step:

- Provisions a 3rd-party resource (new DB, Redis, queue, email-sending domain, deploys beyond free quotas)
- Crosses a usage threshold (free → paid tier)
- Picks a plan during signup
- References pricing-gated features (team seats, audit logs, SSO, custom domains)

**Format:**

```
💰 **Cost note**
- **Free tier:** <what's included> (e.g., "Vercel Hobby: 100 GB
  bandwidth/mo, unlimited preview deploys, no team members")
- **This step costs:** <free / hobby ($X/mo) / pro ($Y/mo)>
- **You'll hit a paywall when:** <specific trigger>
```

If none of those triggers apply, no cost note. A `git commit` step doesn't get one.

---

## Freshness check — when it fires

Add a `*Freshness:*` footer (italics, single line) when the step references:

- A specific UI element on a 3rd-party vendor — any sidebar item, button label, page title
- A CLI flag whose semantics changed in the last 12 months
- A feature launched in the last 6 months relative to today
- Pricing or plan-tier limits

If the step is a stable dev concept (`git rebase`, `npm install`, `console.log`), no freshness footer.

---

## Decision graph

```dot
digraph coach_flow {
  rankdir=TB;
  start [label="user message" shape=doublecircle];
  trigger [label="auto-trigger phrase\nOR /coach invoked?" shape=diamond];
  bypass [label="not coach mode —\nhandle normally" shape=box];
  intent [label="parse intent:\nconcept | procedure |\ndecision | error decode"];
  vendor [label="touches a 3rd-party\ndashboard?" shape=diamond];
  research [label="WebSearch/WebFetch\nvendor docs;\nstamp today's date" shape=box];
  labels [label="pick section labels\nthat fit THIS task"];
  glosses [label="scan response for jargon;\nplan inline gloss for\nevery technical term"];
  triggers [label="check conditional triggers:\ncost? freshness?\nrollback?" shape=box];
  emit [label="emit response:\nexplainer + actions +\nsuccess signal +\nconditional sections"];
  done [label="done" shape=doublecircle];

  start -> trigger;
  trigger -> bypass [label="no"];
  trigger -> intent [label="yes"];
  intent -> vendor;
  vendor -> research [label="yes"];
  vendor -> labels [label="no"];
  research -> labels;
  labels -> glosses;
  glosses -> triggers;
  triggers -> emit;
  emit -> done;
}
```

---

## Rule loading

SKILL.md is self-contained for most invocations. Load references only when needed:

| File | When to load |
|---|---|
| `references/vendor-protocol.md` | Any step touches a 3rd-party dashboard |
| `references/concept-gloss.md` | Multiple jargon terms in one response, or unfamiliar domain |

---

## Quick reference

| You said | Coach does |
|---|---|
| `step by step for X` | Concept first, then numbered actions, then success signal |
| `what does this mean` | The 4-beat gloss + how it shows up in your stack |
| `DONT CODE` | Plans and explains; asks before any file change |
| `walk me through Vercel` | Live-researches Vercel docs; includes "What else you'll see" |
| `in plain english` | Drops audit jargon; everyday analogies; glosses every term |
| `help me understand X vs Y` | "Your options" / "Trade-offs" / "What I'd pick and why" |
