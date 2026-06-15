# Subcommand: `prune`

Memory prune with diff preview.

## TodoWrite Items

```
- [ ] Locate MEMORY.md (project-level or .claude/**/MEMORY.md)
- [ ] If not found, surface skip; STOP
- [ ] Read MEMORY.md index + referenced memory files
- [ ] Read all CLAUDE.md files in the project for comparison
- [ ] Flag candidates: duplicated, contradicted, redundant
- [ ] Present proposed changes as a diff
- [ ] WAIT for user approval
- [ ] Apply approved changes
```

## Workflow

1. Locate MEMORY.md (project-level or `.claude/**/MEMORY.md`).
2. If not found: "No MEMORY.md found. Skipping."
3. Read MEMORY.md index + referenced memory files.
4. Read all CLAUDE.md files in the project for comparison.
5. Flag entries that are:
   - **Duplicated** by a CLAUDE.md file → candidate for removal
   - **Contradicted** by current code → candidate for update or removal
   - **Duplicate** of another memory entry → merge or remove
6. If MEMORY.md > 200 lines, prioritize removal:
   - First: entries now covered by CLAUDE.md files
   - Then: completed phase tracking entries
   - Then: duplicate entries
7. Present proposed changes as a diff for user approval before editing.

## Type label

**Flexible** — pruning is inherently judgment-driven. The diff preview is the gate; never auto-apply.

## Quality Gate

PASS:
- MEMORY.md ≤ 200 lines (or user accepted current size).
- No removed entry contradicts what's in code.

FAIL:
- Removed an entry that codebase still relies on (caught by diff preview approval — should not happen if user reviews).

Recovery: revert the change; re-run with stricter filtering.
