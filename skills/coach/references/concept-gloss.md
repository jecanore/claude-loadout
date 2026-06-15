# Concept gloss reference

Loaded when a response will introduce multiple jargon terms or covers an unfamiliar domain.

## The 4-beat gloss — for load-bearing terms

When the term is the *thing* being explained or done:

```
★ A *<term>* is <one-sentence definition in plain language>.
  Why: <one sentence — what problem it solves or why it exists>.
  How: <one sentence — the mechanism, briefly>.
  Impact: <one sentence — what changes about the user's work>.
```

Worked example:

> ★ *Row-Level Security (RLS)* is a Postgres feature that filters which rows a query can see based on who's running the query.
> Why: lets you store every user's data in one table but ensure user A can never read user B's rows — without writing per-user filters in every query.
> How: you write SQL policies like `auth.uid() = user_id` that Postgres evaluates on every read/write.
> Impact: once enabled, queries that don't match a policy return empty results — common cause of "why is my data missing?" bugs in Supabase.

## The one-line gloss — for peripheral terms

When the term shows up but isn't central:

```
... <action involving term> *(<term>: <8-15 word definition>)* ...
```

Worked example:

> Configure your DNS *(Domain Name System: maps domain names like housingbase.io to server IP addresses)* records to point at Vercel.

## Don't double-gloss

Track terms used in this response. Gloss on first use only. If the user asks again in a future response ("what was RLS again?"), gloss again — that's a fresh first-use.

## Term selection — default to glossing

The user has explicitly requested gloss-on-all-jargon. Default behavior: any technical term, acronym, or domain-specific word gets a gloss on first use.

### Always gloss (the user is learning these)

| Domain | Terms |
|---|---|
| Database | migration, RLS, JWKS, JWT, OAuth, OIDC, RPC, schema, index, foreign key, CTE, transaction, ACID |
| Infra | cron, edge function, cold start, container, runtime, region, availability zone, blue/green deploy |
| Auth | webhook, callback URL, redirect URI, refresh token, access token, scope, claim |
| DNS / domains | DNS, CNAME, A record, TXT record, MX record, nameserver, propagation, TTL |
| Frontend (advanced) | hydration, SSR, SSG, ISR, RSC, suspense, streaming, prefetch |
| Concurrency | Promise, async, await, mutex, race condition, idempotent, debounce, throttle |
| Security | hash, salt, cipher, encoding vs encryption, CSRF, XSS, CORS, CSP |
| Network | polling, long-polling, WebSocket, SSE (Server-Sent Events), gRPC, REST, GraphQL |
| Tooling | linter, formatter, transpiler, bundler, tree-shaking, sourcemap |

### Already known — don't over-gloss

The user uses these daily; brief mention is fine:

- `git` and basic ops: commit, push, pull, branch, merge, clone, fetch *(but DO gloss `rebase`, `cherry-pick`, `reflog`, `stash`, `worktree`)*
- `npm`, `npx`, `pnpm`, `yarn`
- variable, function, array, object, string, number, boolean, null
- HTML, CSS, basic JS / TypeScript syntax (`const`, `let`, `if`, loops)
- env var, `.env` file
- API, endpoint (route paths)
- production / staging / preview / local environments

### When in doubt → gloss

The cost of glossing a known term is one sentence. The cost of skipping a gloss the user needed is another round-trip ("what does X mean?"). Prefer the former.

## Avoid these patterns

- ❌ **Wikipedia-style gloss** — "RLS is a security mechanism in relational database management systems for…" Kill the formality.
- ❌ **Gloss after the fact** — defining a term three paragraphs after first use. Always at first use.
- ❌ **Linking out instead of glossing** — "see the docs for more on JWKS." Embed the gloss; link as supplement.
- ❌ **Stacking glosses in the same sentence** — if three jargon terms appear back-to-back, restructure the sentence rather than glossing each inline. Break into multiple sentences with one gloss each.
- ❌ **Re-glossing the same term in the same response** — track first-use.

## Special case: vendor-specific overloaded terms

The same word means different things across vendors. Always disambiguate:

| Term | Disambiguate |
|---|---|
| "Project" | Vercel (a deployable repo) ≠ Supabase (a database + auth instance) ≠ GitHub (a planning board) |
| "Environment" | Vercel (production/preview/development for env vars) ≠ Supabase (project branches) |
| "Function" | Vercel (Serverless or Edge Function) ≠ Supabase (Edge Function runs on Deno) ≠ Postgres (a stored procedure) |
| "Branch" | git (code branch) ≠ Supabase (DB branch — separate Postgres instance) ≠ Vercel (deploys auto-create per git branch) |

When two vendors both apply, name which: *"a Supabase Project (the database+auth instance, not your Vercel project)"*.
