# Vendor dashboard research protocol

Loaded when any step touches a 3rd-party dashboard.

## Why this exists

Vendor UIs change quarterly. Training-data descriptions go stale fast. The user gets frustrated when a sidebar item we describe doesn't exist or has been renamed. Always research live before producing dashboard steps.

## Procedure

### 1. Identify the canonical doc

Each major vendor has a stable docs URL pattern. Fetch the most relevant page first:

| Vendor | Docs base | Common pages |
|---|---|---|
| Vercel | vercel.com/docs | `/projects/environment-variables`, `/deployments`, `/domains`, `/teams` |
| Supabase | supabase.com/docs | `/guides/auth`, `/guides/database`, `/guides/cli`, `/guides/functions` |
| Namecheap | namecheap.com/support/knowledgebase | search by topic (DNS records, nameservers, redirects) |
| Resend | resend.com/docs | `/dashboard/domains`, `/dashboard/api-keys`, `/send-with-supabase-smtp` |
| Upstash | upstash.com/docs | `/redis/overall/getstarted`, `/redis/howto`, `/qstash` |
| Stripe | stripe.com/docs | `/api`, `/payments/quickstart`, `/billing` |
| Cloudflare | developers.cloudflare.com | `/pages`, `/workers`, `/dns/manage-dns-records` |
| GitHub | docs.github.com | `/actions`, `/repositories`, `/authentication` |

If unsure, WebSearch with: `<vendor> <feature> dashboard 2026 site:<vendor-domain>`.

### 2. Extract three things

1. **The exact navigation path** — sidebar item names, page titles, button labels (in the vendor's current copy, including capitalization).
2. **All adjacent UI options on the same page** — the user wants to learn what each does, not just complete the task.
3. **Recent UI changes** — vendors often note "We've moved this" or have a deprecation banner. Surface these.

### 3. Format the step

Use the `Vendor dashboard steps` format from SKILL.md. Required *content* (label each per task — don't reuse the same words mechanically):

- **A freshness stamp** — e.g. `*Verified against <vendor> docs on YYYY-MM-DD.*` (label could be "Freshness", "Verified", or inline italics)
- **Action bullets** — one verb per bullet (`Open` / `Navigate` / `Click` / `Fill` / `Save` is a useful default vocabulary, but rename when the task calls for it — e.g. `Search`, `Toggle`, `Confirm`, `Paste`)
- **A success signal** — `✅ Success:` or `✅ You should now see:` or whatever fits
- **A gotcha callout** *(when applicable)* — `★ Gotcha:` or `⚠️ Watch out:` or `Heads up:`
- **An adjacent-options enumeration** — labeled per task: *"What else you'll see"*, *"Other things on this page"*, *"Don't worry about these for now, but here's what they do"*

The **content** is non-negotiable. The **labels** flex per task — same flexibility rule that governs SKILL.md output sections.

## Edge cases

| Situation | How to handle |
|---|---|
| **Login wall** | Don't describe the login screen. Just say "Log in to <vendor>." |
| **Multi-step wizard** | Each screen is its own numbered step. Don't pile screens into one bullet. |
| **A/B-tested layouts** | Mention both. *"Some accounts see a sidebar; others see top tabs — both have the same items."* |
| **Account-tier differences** | Note them. *"Free accounts won't see the 'Team Members' option — that's Pro+."* |
| **Mobile vs desktop** | Assume desktop unless the user says otherwise. |
| **Login MFA prompt** | Say *"complete 2FA / MFA"* — don't pretend to walk through codes. |
| **Vendor uses a CLI you can run for them** | Prefer the CLI route as a "Tell Claude:" prompt; keep dashboard as alternative. |

## What NOT to do

- **Don't paraphrase from memory.** Always fetch the current docs.
- **Don't omit "What else you'll see"** because it feels like padding. The user's stated goal is dashboard literacy, not single-task completion.
- **Don't reference screenshots** in your response — you can't render them, and pretending to describes a fictional UI.
- **Don't reuse vendor-X jargon in vendor-Y context** without re-glossing. A "Project" in Supabase means different things from a "Project" in Vercel.
- **Don't skip the freshness stamp** even if the docs page hasn't changed in months. The stamp is the user's signal that you actually checked.

## When live research fails

If WebSearch/WebFetch returns nothing useful or is blocked:

1. State explicitly: *"I couldn't fetch live docs for this — what I'm describing below is from training data and may be out of date. The labels below have been roughly stable, but verify each one before clicking."*
2. Proceed with best-effort steps.
3. Add a stronger freshness warning: *"⚠️ Training-data only. Vendor UIs change; verify each step."*

Never silently fall back to memory. The user must know which is which.
