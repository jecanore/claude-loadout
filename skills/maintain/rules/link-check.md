# Rule: link-check

Detection and validation rules for markdown links. Loaded by [`/maintain links`](../references/subcommands/links.md).

## Link Forms to Detect

| Form | Example | Type |
|---|---|---|
| Inline link | `[text](path)` | link |
| Reference link | `[text][ref]` + `[ref]: path` | link (resolved via reference) |
| Autolink | `<https://example.com>` | link |
| Image | `![alt](path)` | image (existence check) |
| HTML anchor | `<a href="path">text</a>` | link |
| HTML img | `<img src="path">` | image |
| Bare URL | `https://example.com` (in plain text) | link (only if `--lint-bare-urls` enabled) |

## Resolution Rules

### Relative path

`./foo.md`, `../bar/baz.md`, `foo.md` (no leading `./`)

Resolve against the directory containing the source markdown file. Honor symlinks (resolve to real path before existence check).

### Absolute repo path

`/docs/foo.md` — interpret as repo-rooted (NOT filesystem-rooted).

Resolve against `git rev-parse --show-toplevel`.

### Anchor (intra-doc)

`#section-name`

Match against headings in the same file. Slugify rule:
- lowercase
- replace spaces with `-`
- strip punctuation except `-`
- collapse multiple `-`
- example: `## Getting Started!` → `getting-started`

### Anchor (cross-doc)

`./other.md#section`

Resolve `./other.md` first; then check `#section` against headings in that file.

### External URL

`https://...` or `http://...`

**Only** check if user opted in for this session.

If checked:
- HEAD request with 5s timeout.
- Rate limit: 5 requests/sec, max 50/file, max 200/run.
- Treat 2xx, 3xx, 401 as OK (auth-required pages exist).
- Treat 404, 410, 5xx as broken.
- Treat 403, 429 as INDETERMINATE — surface but do not flag as broken.
- Treat connection errors, timeouts as INDETERMINATE.
- Cache results for the session to avoid re-fetching.

### Special schemes

Skip without checking: `mailto:`, `tel:`, `sms:`, `data:`, `javascript:`.

## Headings & Slugs

When parsing headings:
- Skip headings inside fenced code blocks (` ``` ` or `~~~`).
- Skip headings inside HTML comments.
- Handle GitHub-flavored anchors (which collapse adjacent `-`).
- For duplicate slugs in the same file, GitHub appends `-1`, `-2`. Match either form.

## False Positives

These are not "broken" — surface only with `--strict`:
- Anchors in unfenced code that look like links (`http://example.com` inside an indented code block).
- Links to the literal text `path/to/file.md` in instructional copy ("save this as `path/to/file.md`").

Use surrounding context: if the link is inside backticks or a fenced code block, skip.

## Output

Each finding:

```ts
{
  file: string;
  line: number;
  target: string;       // raw link target as written
  resolvedTo?: string;  // absolute path or normalized URL
  reason: 'missing-file' | 'missing-anchor' | 'http-error' | 'fragment-not-found' | 'indeterminate';
  httpStatus?: number;
  rule: 'internal-file' | 'internal-anchor' | 'external-url';
}
```

## Auto-fix Candidates (still gated by user approval)

| Pattern | Fix |
|---|---|
| Case mismatch on filesystem (`./Readme.md` → `./README.md` exists) | propose path correction |
| Missing extension (`./foo` → `./foo.md` exists) | propose extension addition |
| Anchor case/slug mismatch (`#Getting-Started` vs `## Getting started`) | propose anchor correction |
| Trailing slash difference (`./docs/` vs `./docs`) | propose normalization |

## Never

- Auto-fix broken links to draft pages (path doesn't exist anywhere).
- Auto-remove broken links (might be intentional placeholders).
- Make external HTTP requests without user opt-in.
- Follow redirects when checking external links (HEAD only).
