# claude-loadout

The exact Claude Code skill stack I ship with as a solo founder dev. Opinionated. Battle-tested on production SaaS.

11 original skills + a curated manifest of upstream skills worth installing.

---

## What's in here

### Original skills (`skills/`)

Built and maintained by [@jecanore](https://github.com/jecanore). MIT licensed.

| Skill | What it does |
|---|---|
| `cmux-parallel-agents` | Run N Claude sessions in parallel without corrupting each other — the four traps, isolation architectures, full runbook |
| `github-sentinel` | Monitor CI/PR/notifications across all your repos with explicit safety gates |
| `vet-recommendation` | Structured confidence report before you act on any tool, library, or service recommendation |
| `technical-writing` | Prose standards for docs, READMEs, commit messages, PR descriptions — Elements of Style meets UX writing |
| `SEO-GEO-writing` | Blog posts, landing pages, and marketing content with SEO/GEO principles built in |
| `coach` | Beginner-friendly mode — explains while doing, no code edits, glosses every term |
| `maintain` | Full maintenance pass: sync docs, fix stale refs, cut a CHANGELOG, detect lockfile drift, scan for secrets |
| `skill-modernizer` | 10-pattern audit/modernize/create system for keeping your own skills high-quality |
| `contribute` | Full OSS contribution workflow — fork to merge with quality gates |
| `mobile-design` | Mobile UX patterns, touch interactions, gesture design, mobile-first principles |
| `accessibility-compliance` | WCAG 2.2 implementation — ARIA, keyboard nav, screen readers, focus management |

### Upstream skills (see `MANIFEST.md`)

Skills from other authors that I use daily. See [MANIFEST.md](./MANIFEST.md) for full attribution and install commands.

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
./install.sh --originals-only   # skip npx skills add calls
./install.sh --upstream-only    # skip copying from this repo
```

Restart Claude Code after installing.

---

## Philosophy

Parallel agents aren't cheaper than sequential — they save wall-clock time and keep contexts small. This loadout is built around that model: parallel work, tight skill surfaces, explicit quality gates.

The `skill-modernizer` skill ships with this repo so you can audit and evolve any skill here using the same 10-pattern rubric they were built against.

---

## License

MIT — original skills only. Upstream skills retain their own licenses (see MANIFEST.md).
