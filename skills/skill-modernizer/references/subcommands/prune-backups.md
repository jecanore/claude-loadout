# `prune-backups` — manage backup retention

**Loads on entry:**
- `references/state-schema.md` (`BackupRecord` shape)

**Type:** rigid, mutating

---

## Workflow

```
INDEX → SELECT → CONFIRM → DELETE
```

Mutates the on-disk backup directory and appends an updated entry to the backup index JSONL.

---

## Steps

1. **Pre-gate.**
   - Resolve backup root: `<your Claude config directory>/.backups/skill-modernizer/`.
   - If the root doesn't exist, report "no backups found" and exit cleanly.

2. **Index.**
   - Read `<backup-root>/index.jsonl` line-by-line.
   - Build the in-memory list of `BackupRecord` entries.
   - Filter out entries whose backup directories no longer exist on disk (orphaned index entries — flag in warnings but don't auto-prune the index).

3. **Select candidates.**
   - Apply retention policy:
     - Per skill, keep the **last 3 verified backups** within the **30-day TTL**.
     - Backups older than 30 days are candidates regardless of count.
     - Unverified backups have an additional 7-day grace period.
   - Filter by flags:
     - `--all` selects all backups across all skills.
     - `--skill <name>` restricts to one skill.
     - `--older-than <days>` overrides the default 30-day TTL.

4. **Confirm.**
   - Show the user the list of candidates: skill name, age, status, path.
   - Wait for explicit `y` / `n` confirmation.
   - On `n` (or any non-`y` input): abort cleanly. No changes made.

5. **Delete.**
   - For each approved candidate: `rm -rf <backup-dir>`.
   - Append a `pruned` entry to `index.jsonl` (append-only — never mutate prior lines).
   - Pruned-entry shape:
     ```jsonl
     {"ts":"<ISO-timestamp>","skill":"<name>","action":"prune","path":"<backup-dir>","reason":"ttl-expired|count-exceeded|user-explicit"}
     ```

6. **Report.**
   - Emit summary: scanned N, deleted M, retained K.
   - Optional `--json` output per `rules/json-schema.md` (`prune-backups` schema).

---

## Flags

| Flag | Default | Purpose |
|---|---|---|
| `--all` | off | Select every backup, ignoring per-skill retention |
| `--skill <name>` | (all) | Restrict to one skill |
| `--older-than <days>` | 30 | Override TTL |
| `--dry-run` | off | Report what would be deleted; do not delete |
| `--json` | off | Emit JSON output |

`--dry-run` skips step 5 entirely. Useful for CI or for verifying before a real prune.

---

## Report format (default)

```
Backup retention scan
─────────────────────
Scanned:    47 backups across 12 skills
Candidates: 12 (8 ttl-expired, 4 count-exceeded)
Retained:   35

Candidates to delete:
  - my-skill-A   <ISO-date> (45d, verified)   ttl-expired
  - my-skill-A   <ISO-date> (38d, verified)   ttl-expired
  ...

Proceed? [y/N]:
```

After confirmation:

```
Deleted:    12
Retained:   35
Index updated: 12 prune entries appended
```

---

## Report format (with `--json`)

Per `rules/json-schema.md` `prune-backups` schema. Top-level result:

```json
{
  "scanned": 47,
  "deleted": 12,
  "retained": 35,
  "retention_policy": { "max_per_skill": 3, "ttl_days": 30, "unverified_extra_days": 7 },
  "deleted_paths": ["<absolute-path>"]
}
```

---

## What `prune-backups` never does

- Never mutates a backup directory (only deletes it whole).
- Never rewrites prior `index.jsonl` lines (append-only).
- Never skips the confirmation gate, even with `--all`.
- Never deletes a backup currently locked by an in-progress mutation. (If `index.jsonl` shows a recent `unverified` entry from a still-running operation, leave it alone and warn.)
- Never deletes the backup root directory itself, only its child snapshots.

---

## Why this exists

Backups accumulate. Without bounded retention, disk usage grows unboundedly. The default policy (3 per skill + 30-day TTL) is conservative; `prune-backups` is the manual-and-automated escape hatch for users who need different bounds.
