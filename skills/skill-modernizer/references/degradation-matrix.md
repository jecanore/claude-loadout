# Degradation matrix — handling unusual targets

**Loaded by:** `audit`, `score`, `modernize`, `migrate` (when target structure is unusual)

**Purpose:** Defines how `skill-modernizer` behaves when a target skill has a non-standard structure. The goal is to **always produce a useful output**, never crash, never silently misinterpret.

---

## When to consult this matrix

After detecting target structure (frontmatter, file tree, archetype), if any of the following holds:

- Frontmatter is missing or malformed.
- `SKILL.md` is missing entirely.
- The directory layout doesn't match any archetype.
- A required file referenced in SKILL.md doesn't exist.
- A reference file is loaded by SKILL.md but has no content.
- The target is a symlink chain.
- The target uses an unsupported file extension (`.skill` instead of `.md`, etc.).

---

## Degradation rules

### Missing `SKILL.md` at target root

**Behavior:** Pre-gate fails. STOP and report:

```
Target at <path> has no SKILL.md. This may be a directory of skills (parent of skills) rather than a skill itself. Try `audit-all <path>` to audit each skill in the directory.
```

Never attempt to "guess" which file is the SKILL.md. Never proceed with mutating subcommands.

### Malformed frontmatter

**Behavior:** Continue with warnings. Treat the skill as `archetype: unknown`. The audit report includes a top-level warning: "frontmatter is malformed; some checks degraded".

For each malformed-frontmatter implication:
- `name:` missing → use directory name as fallback for reporting.
- `version:` missing → treat as `0.0.0`.
- `allowed-tools:` missing → pattern #7 reports `absent`.
- Unparseable YAML → treat as if frontmatter is empty; report a `partial` finding for any pattern that depends on frontmatter.

### Frontmatter present but archetype undetectable

**Behavior:** Set `archetype: unknown` in state. Use **`single-purpose-rigid` weights** as a conservative default for grading. The audit report includes:

```
Archetype could not be detected. Defaulting to single-purpose-rigid weights for scoring. To set explicitly, add `archetype: <one-of-four>` to frontmatter.
```

`modernize` refuses to run on `unknown` archetypes — the user must clarify the archetype first (`modernize` cannot guess what skeleton to fill).

### Unusual directory layout

**Behavior:** Proceed with audit, noting deviations. Examples:

- `references/` exists but contains no `subcommands/` and SKILL.md doesn't reference subcommands → fine; not all archetypes need this.
- `rules/` exists but no `references/` → fine; report as note only.
- Both `references/` and `lib/` exist → flag as `format-variance`; suggest consolidating into `references/`.
- A flat layout with no subdirectories → fine for `single-purpose-rigid` and `single-purpose-flexible` and `reference-only`. For `orchestrator-with-subcommands`, flag as a `partial` for pattern #8.

### Reference files loaded but missing

**Behavior:** Audit reports as `partial` for pattern #8 (`references/` progressive disclosure). The note specifies which referenced file is missing:

```
SKILL.md references `rules/migration-map.md` but the file does not exist. Pattern #8 marked partial.
```

`modernize` offers to either create the missing file as a stub, or remove the reference from SKILL.md. The user gates the choice.

### Reference file exists but is empty

**Behavior:** Treat similarly to missing — `partial` for pattern #8 with note "empty reference file". `modernize` offers to populate or remove.

### Symlink chain

**Behavior:** Resolve the symlink, work on the resolved path. Add a note to the report indicating the resolution. If the symlink resolves outside the user's skills directory or into a plugin cache, surface that explicitly:

```
Target <path> resolves via symlink to <resolved>, which is in a plugin cache. Mutating subcommands will refuse.
```

### Unsupported file extension

**Behavior:** If `SKILL.md` is missing but a `SKILL.skill` or `skill.yaml` is present, surface a clear error:

```
Found SKILL.<ext> but expected SKILL.md. This skill format is not supported.
```

Never attempt to convert formats automatically.

### Target is a single file (no directory)

**Behavior:** Some skill systems support flat single-file skills. Proceed with audit, treating `<file>` as the SKILL.md and skipping pattern #8 (no `references/` possible) — mark as `n/a` per archetype.

### Empty SKILL.md

**Behavior:** Pre-gate passes (file exists), but audit reports overall grade `F` with note "skill has no detectable structure". No fix hints emitted because there's nothing to anchor against.

`modernize` refuses to run — there's no content to modernize. Suggest `create` instead.

### Frontmatter says `archetype: reference-only` but file has subcommands

**Behavior:** Flag as a `partial` for pattern #6 (rigid/flexible labeling) with note "archetype declared as reference-only but workflow detected". The audit grade reflects rule by archetype, so the user can either fix the archetype declaration or remove the workflow.

---

## Errors `skill-modernizer` should never throw

Even with weird inputs, these failure modes should never occur:

- **Crash without report.** Always emit at least a JSON or text payload with `errors[]` populated.
- **Silent misinterpretation.** If the archetype is ambiguous, say so; don't pick one and run.
- **Mutation without gate.** Never apply edits without an explicit approval, regardless of how "obvious" the fix is.
- **Backup skipped because target is small.** Backups are insurance; size doesn't matter.
- **Reference file silently dropped.** Always preserve. If obsolete, mark with a disclaimer header.

---

## Rationale

The skill exists to enforce discipline on skills. Its own behavior under unusual inputs is the most visible test of that discipline. When in doubt, surface the situation and stop, rather than guess.
