# Structural Check Patterns

Detailed patterns for validating skill structure and metadata.

## LOW — Missing or Invalid Frontmatter

Flag structural issues with the skill definition:

- No `SKILL.md` file in the skill directory
- SKILL.md without YAML frontmatter (`---` delimiters)
- Missing `name` field in frontmatter
- Missing `description` field in frontmatter
- Description exceeds 1024 characters
- Name contains spaces or special characters (should be kebab-case or snake_case)

## LOW — Undocumented Scripts

Flag scripts that exist without documentation:

- Files in `scripts/` directory not referenced in SKILL.md
- Executable files (`.sh`, `.py`, `.js`) not documented
- Scripts with no comments or inline documentation
- Package.json scripts not explained in SKILL.md

## MEDIUM — Mandatory Untrusted Execution

Flag when the skill requires running code from untrusted sources:

- "Run this script before using the skill" without the script being auditable in the repo
- Scripts downloaded at runtime (not included in the skill directory)
- Post-install hooks that fetch and execute remote code
- Setup instructions that require `curl | sh` from external URLs

## LOW — Excessive Scope

Flag skills that seem overly broad for their stated purpose:

- Description claims narrow scope but SKILL.md contains instructions for many unrelated actions
- Skill requests access to tools or directories unrelated to its stated purpose
- Large number of files in skill directory relative to stated functionality

## LOW — Missing License or Attribution

Flag potential intellectual property concerns:

- No license file or license field
- Code that appears copied from known projects without attribution
- Proprietary-looking code in a public skill

## False Positive Indicators

- Skills with complex setup that legitimately require multiple scripts
- Skills that generate files as part of their workflow (documented in SKILL.md)
- Monorepo skills that share a directory with other skills
