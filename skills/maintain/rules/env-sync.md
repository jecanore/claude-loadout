# Rule: env-sync

Detection rules for `.env.example` ↔ runtime-env-read drift. Loaded by [`/maintain env`](../references/subcommands/env.md).

## Detection Patterns

### TypeScript / JavaScript

```regex
process\.env\.([A-Z][A-Z0-9_]+)
process\.env\["([A-Z][A-Z0-9_]+)"\]
process\.env\['([A-Z][A-Z0-9_]+)'\]
import\.meta\.env\.([A-Z][A-Z0-9_]+)        # Vite
```

Also detect Zod / Valibot / Yup config schemas:

```ts
const envSchema = z.object({
  DATABASE_URL: z.string(),     // ← capture left-hand keys
  PORT: z.coerce.number(),
});
```

Heuristic: when `z.object({...})`, `valibot.object({...})`, or `Yup.object({...})` is assigned to a name containing `env`/`config`/`settings`, capture the keys.

### Python

```regex
os\.environ\.get\(["']([A-Z][A-Z0-9_]+)["']
os\.environ\[["']([A-Z][A-Z0-9_]+)["']\]
os\.getenv\(["']([A-Z][A-Z0-9_]+)["']
```

Pydantic `BaseSettings` / pydantic-settings:

```python
class Settings(BaseSettings):
    DATABASE_URL: str        # ← capture field names that are UPPERCASE
    PORT: int = 8000
```

### Ruby

```regex
ENV\[["']([A-Z][A-Z0-9_]+)["']\]
ENV\.fetch\(["']([A-Z][A-Z0-9_]+)["']
```

### Go

```regex
os\.Getenv\("([A-Z][A-Z0-9_]+)"\)
os\.LookupEnv\("([A-Z][A-Z0-9_]+)"\)
```

### Rust

```regex
std::env::var\("([A-Z][A-Z0-9_]+)"\)
std::env::var_os\("([A-Z][A-Z0-9_]+)"\)
env!\("([A-Z][A-Z0-9_]+)"\)
```

### PHP

```regex
getenv\(["']([A-Z][A-Z0-9_]+)["']\)
\$_ENV\[["']([A-Z][A-Z0-9_]+)["']\]
```

## Excluded Scopes

When detecting code-side env reads, exclude:
- `**/test/**`, `**/__tests__/**`, `**/tests/**`
- `**/*.test.{ts,tsx,js,jsx,py,rb,go,rs,php}`
- `**/*.spec.{ts,tsx,js,jsx}`
- `**/__fixtures__/**`, `**/fixtures/**`
- `**/node_modules/**`, `**/vendor/**`
- Comments (single-line `//`, `#`, multi-line `/* */`)
- String literals inside comments

Tests sometimes set env vars they don't read in production code. Including them produces false drift.

## Drift Algorithm

```
code_vars = union of detected vars across all non-excluded files
example_vars = parse .env.example (KEY=VALUE form, ignore comments and blank lines)

missing-in-example = code_vars \ example_vars
removed-in-code   = example_vars \ code_vars
name-changed candidates = pairs (a, b) where a ∈ missing-in-example, b ∈ removed-in-code, edit_distance(a, b) ≤ 2
```

## .env.example Edit Strategy

Preserve user formatting:

1. **Read existing structure** — section headers (`# Authentication`), blank lines, inline comments.
2. **For each missing-in-example var:**
   - If can infer category from surrounding code context (e.g., var is referenced near auth code), suggest the matching section.
   - Otherwise, append under `# Auto-detected (review and re-categorize)` section at the bottom.
3. **Default value:**
   - For booleans: `false`
   - For numbers (`PORT`, `TIMEOUT_MS`): empty
   - For URLs: empty (`DATABASE_URL=`)
   - Otherwise: `YOUR_VALUE_HERE`
4. **Add a comment** above each new entry: `# (auto-added by /maintain env from {file}:{line})`.

## Never

- Auto-remove any `.env.example` entry without user approval.
- Auto-merge `name-changed` candidates without user approval.
- Read or write actual `.env` files (only `.env.example`).
- Commit secrets — `.env.example` should contain placeholders only.
