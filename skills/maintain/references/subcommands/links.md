# Subcommand: `links` (new 2026-05)

Crawl markdown for broken internal/external links. External fetch is opt-in per session.

## TodoWrite Items

```
- [ ] Determine scope (default: all tracked .md files)
- [ ] Ask user: include external link checks? (HTTP traffic, off by default)
- [ ] Parse all markdown files; extract links and anchors
- [ ] Validate internal file links (relative paths and absolute repo paths)
- [ ] Validate intra-doc anchors (#headings)
- [ ] Validate cross-doc anchors
- [ ] If external enabled: HEAD-fetch external URLs with rate limit; record HTTP status
- [ ] Aggregate broken links into state.brokenLinks
- [ ] Present report (never auto-edit)
- [ ] On approval, optionally fix obvious typos (case mismatch, missing extension)
```

## Detection Patterns

Load `rules/link-check.md`. Match:
- `[text](path)` — markdown link
- `[text]: path` — reference-style link definition
- `<https://...>` — autolink
- `![alt](path)` — image (treated as link for existence check)
- HTML `<a href="...">` and `<img src="...">` (when present in markdown)

## Validation Rules

| Link Type | Check |
|---|---|
| Relative file (`./foo.md`, `../bar/baz.md`) | file exists at resolved path |
| Absolute repo path (`/docs/foo.md` — repo-rooted) | file exists |
| Intra-doc anchor (`#section`) | a heading `## Section` (case-insensitive, slug-matched) exists in same file |
| Cross-doc anchor (`./other.md#section`) | target file exists AND target heading exists |
| External URL (https://, http://) | only checked if user opted in for this session; HEAD request with 5s timeout, rate-limited 5/sec |
| `mailto:`, `tel:` | not checked |
| Image with `srcset` or width attrs | parse and check the primary src only |

## External Link Caveats

External link checks **require user opt-in**. They:
- Make outbound HTTP traffic (privacy + corp-policy concern).
- Hit rate limits on services like GitHub/Stack Overflow.
- Produce false positives (sites returning 403 on HEAD but 200 on GET; Cloudflare challenges).

Default: internal-only. Offer external as opt-in per invocation.

## Edit Strategy

**Never auto-fix** broken links by default. Surface in report. Optional auto-fix targets:
- Case mismatch in file path (`Readme.md` → `README.md`) → propose, await approval.
- Missing extension (`./foo` → `./foo.md` if `./foo.md` exists) → propose, await approval.
- Anchor case/slug mismatch (`#getting-started` → `#getting-started` after slugifying actual heading) → propose, await approval.

## Type label

**Flexible** — broken links may be intentional (drafts, intentionally dead). Always present, never auto-edit without user.

## Quality Gate

PASS:
- Modified-file sweep returns zero broken internal links.
- All anchors resolve.
- (If external enabled) all external links return 2xx OR user has acknowledged 4xx/5xx hits.

FAIL:
- Internal links broken AND user has not acknowledged.

Recovery: surface report; iterate with user.

## Verification §D (lives in rules/verification.md)

```
1. Re-parse all modified .md files for links.
2. Re-validate every link.
3. Assert: no internal-broken links remain.
4. Report status of external links if checked.
```
