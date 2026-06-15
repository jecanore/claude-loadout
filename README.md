# claude-loadout

13 original skills built by a solo founder who learned the hard way that AI coding agents are powerful and wrong in equal measure.

This isn't a "prompt library." It's a layer of judgment I built on top of Claude Code — skills that slow me down at exactly the moments I shouldn't be moving fast, and speed me up everywhere else.

---

## The origin

I was building fast. AI agent suggested a library. Looked great, fit the use case, I shipped it. Turned out it was deprecated, had a known security issue, and the community had moved on 18 months ago. Two days to unwind.

That was the moment I stopped treating AI recommendations as facts and started treating them as hypotheses that needed verification. `vet-recommendation` was the first skill I wrote. The rest followed from the same instinct: **don't trust, verify, then act.**

A few of these came from shipping something that worked on my machine but failed a real user — accessibility and mobile especially. A few came from hitting a new area of CS I'd never worked in and needing to actually *learn* it, not just copy-paste code I didn't understand. And a few just came from opening old repos and finding chaos.

---

## How to read this

Skills aren't tools you reach for randomly. They map to project lifecycle stages. Here's when each one earns its keep — roughly in the order you'd hit them on a real project.

---

## Phase 1 — Before you build anything

### `Remote_Skill_Security_Check`

**The problem it solves:** You're about to install a skill someone else wrote. It runs inside your Claude Code session with access to your files, your tools, your git history. A malicious skill could exfiltrate code, inject instructions, or escalate permissions — and it would look like normal AI behavior until something went wrong.

**When to use it:** Before running `npx skills add <anything>` from a source you haven't reviewed yourself. It fetches the skill read-only, checks for prompt injection patterns, data exfiltration attempts, permission escalation, and dangerous tool usage. Gives you a severity-rated report before you decide whether to install.

**Origin:** I was building `skill-modernizer` and kept writing "install this composer skill first" flows. That meant users (and me) would routinely run `npx skills add` on skills we'd never audited. The trust surface is real — a skill is code that executes in your agent. I built this so there's always a checkpoint before that trust is extended.

---

### `vet-recommendation`

**The problem it solves:** AI agents recommend things with confidence regardless of whether those things are good. The library might be abandoned. The pattern might be an antipattern. The service might have changed its pricing model three months ago.

**When to use it:** Any time Claude (or anyone) recommends a library, service, API, tool, or architectural pattern and you're about to act on it. Especially when it "just sounds right."

**Origin:** See above. Deprecated library, two wasted days. Now I run this before I `npm install` anything I haven't personally vetted.

---

### `coach`

**The problem it solves:** There's a difference between "get this working" and "understand what I just built." The default mode of AI coding agents is the former. `coach` forces the latter — it explains while doing, never edits code without you understanding the change, and glosses every term you might not know.

**When to use it:** When you're in a domain that's new to you. When you want to actually understand a pattern, not just use it. When someone junior is pair-programming with you via Claude.

**Origin:** I kept shipping code I didn't fully understand. Fine until something broke — then I had no mental model to debug from. `coach` is the mode I use when understanding matters more than speed.

---

### `academy`

**The problem it solves:** Sometimes it's not one new library — it's a whole area of CS you've never touched. Auth flows, database internals, distributed systems, WebSockets, whatever. You need structure, not a one-liner.

**When to use it:** When you're entering a domain you've never worked in and you want a curriculum, not just answers. Think of it as the difference between Googling a symptom and actually reading the textbook chapter.

**Origin:** I was building something that required understanding RLS and row-level security from scratch. I didn't want Claude to just write the policies — I wanted to know why they worked. `academy` gave me a structured path through it.

---

## Phase 2 — While you're building

### `cmux-parallel-agents`

**The problem it solves:** Running parallel Claude sessions is great for speed and terrible for your git history. Staged files from one session end up in another's commit. Two agents touch the same file. Someone resets the branch. It's a mess.

**When to use it:** The moment you spin up more than one Claude session against the same repo. There are four main traps, specific isolation architectures for each, and a full runbook. Read this *before* things go sideways, not after.

**Origin:** Five parallel sessions, same branch, concurrent commits. The staging area was contaminated. Two commits had each other's files. I documented every failure mode so I'd never repeat it.

---

### `accessibility-compliance`

**The problem it solves:** WCAG compliance is not a post-launch audit. By then it's expensive to fix. ARIA roles, keyboard navigation, focus management, screen reader compatibility — this skill bakes the checks into the build phase.

**When to use it:** When building any UI component, form, modal, or interactive element. Run it before you call something done, not after a user reports it broken.

**Origin:** Shipped a feature. Got a message from a user who relied on a screen reader. Completely broken for them. I'd never once thought about it during development. That was the last time.

---

### `mobile-design`

**The problem it solves:** Desktop-first design looks great until it hits a real phone. Touch targets too small to tap. Scroll behavior fighting the browser. Gestures that conflict with native swipes. Mobile design patterns are genuinely different from desktop patterns, and they need to be applied during build, not patched after.

**When to use it:** When building any UI that will run on a mobile device. Covers touch interactions, gesture design, safe areas, thumb reach zones, and mobile-first layout principles.

**Origin:** Same story as accessibility, different device. iPhone 12, production, embarrassing. I built this the week after.

---

## Phase 3 — Shipping

### `technical-writing`

**The problem it solves:** Commit messages that say "fix bug." READMEs that describe a version from two refactors ago. PR descriptions that make reviewers guess at the why. Good technical writing is a force multiplier — it makes your future self and collaborators faster.

**When to use it:** Writing a README, a PR description, a commit message, API docs, a CHANGELOG entry, or any technical prose. Not just "make it longer" — make it precise, scannable, and honest.

**Origin:** I opened a PR I'd written three months earlier and had no idea what I was looking at. The commit messages were useless. I wrote this to enforce the standards I actually wanted, consistently.

---

### `SEO-GEO-writing`

**The problem it solves:** Marketing content that gets zero traffic isn't marketing — it's journaling. SEO and GEO (generative engine optimization — appearing in AI-generated answers) require specific structural decisions from the first draft, not as a layer you add later.

**When to use it:** Landing pages, blog posts, feature announcements, anything public-facing where you want distribution. Handles both traditional search and AI answer engines.

**Origin:** Wrote a launch post that got three views. All three were me. Rebuilt it with this skill's principles and it actually found its audience.

---

## Phase 4 — Ongoing

### `github-sentinel`

**The problem it solves:** As a solo dev across multiple repos, monitoring is death by a thousand tabs. PRs waiting, CI failing silently, notifications that have been sitting unread for a day. `github-sentinel` does one sweep and surfaces what actually needs your attention — with explicit safety gates so you don't accidentally merge something you haven't reviewed.

**When to use it:** Daily, as a morning ritual. Or whenever you've been heads-down for a few hours and need to resurface.

**Origin:** I'd context-switch to check GitHub and lose 20 minutes. Then I'd miss something important because I checked the wrong tab. I needed one sweep, not fifteen.

---

### `maintain`

**The problem it solves:** Repos rot. Deps go stale. READMEs reference routes that don't exist. Lockfiles drift. Sometimes a secret ends up in an old commit you forgot about. `maintain` does the full sweep — docs, deps, CHANGELOG, secrets scan — in one pass.

**When to use it:** Monthly, or whenever you come back to a repo you haven't touched in a while. Also a good pre-release checklist.

**Origin:** Opened a six-month-old repo, found 47 dependency warnings, a broken link in the README, and a `.env` file that had been committed once before I added it to `.gitignore`. One skill, full sweep, never again.

---

### `contribute`

**The problem it solves:** Contributing to open source has a specific workflow — fork, branch, implement, test, PR, respond to review, iterate — and it's easy to skip steps or miss the project's conventions. A rejected PR because of a style issue or a missing test wastes everyone's time.

**When to use it:** Any time you're submitting code to a project you don't own. From "found a bug and want to fix it" through "PR merged."

**Origin:** My first OSS contribution got closed immediately because I'd pushed to main instead of a feature branch and hadn't run their test suite. This skill codifies the full process so you make a good first impression.

---

## Meta — Always available

### `skill-modernizer`

**The problem it solves:** Skills drift. You write one in January, use it through April, and by then it has gaps, outdated assumptions, or missing patterns. `skill-modernizer` is a 10-pattern audit and modernization system for any skill — including the ones in this repo.

**When to use it:** When a skill feels like it's not quite covering your current situation. When you want to write a new skill from scratch. When you want to score and improve an existing one. It's the meta-layer that keeps everything else sharp.

**Origin:** I kept hitting edge cases that a skill didn't handle. Instead of just living with it, I built a structured way to audit and improve skills. It ships with this repo because it's the first thing you should reach for when any skill stops serving you.

---

## Install

```bash
git clone https://github.com/jecanore/claude-loadout
cd claude-loadout
chmod +x install.sh
./install.sh
```

Options:
```bash
./install.sh --originals-only   # skip npx skills add calls for upstream skills
./install.sh --upstream-only    # skip copying from this repo
```

Restart Claude Code after installing.

---

## Upstream skills (see `MANIFEST.md`)

This repo ships originals only. I also daily-drive a set of upstream skills from other authors — full attribution and install commands in [MANIFEST.md](./MANIFEST.md).

---

## The model

Parallel agents are faster than sequential. Tight skill surfaces beat monolithic prompts. Explicit quality gates beat hoping Claude got it right. This loadout is built around that model.

The ordering above is a lifecycle guide, not a strict sequence. Real development is messier — you'll be in Phase 3 and realize you need `coach` for something, or you'll be in Phase 2 and `vet-recommendation` surfaces something that changes your approach entirely. The phases are anchors, not walls.

---

## License

MIT — original skills only. Upstream skills retain their own licenses (see MANIFEST.md).
