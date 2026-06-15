# State schema — `SkillModernizerState`

**Loaded by:** all subcommands (shared)

**Purpose:** Defines the in-memory state shape that subcommands read and write. Centralized so `audit`, `modernize`, `migrate`, `create`, `refresh`, etc., share one understanding of what an "audit result" or "backup index entry" looks like.

---

## Top-level state

```ts
interface SkillModernizerState {
  invocation: InvocationContext;
  target: TargetSkill | null;
  composers: ComposerStatus;
  audit: AuditResult | null;
  modernize: ModernizePlan | null;
  create: CreatePlan | null;
  refresh: RefreshPlan | null;
  backup: BackupRecord | null;
}
```

---

## InvocationContext

```ts
interface InvocationContext {
  subcommand: "audit" | "score" | "modernize" | "migrate" | "create"
            | "pressure-test" | "refresh" | "audit-all" | "prune-backups";
  args: string[];
  flags: { json?: boolean; parallelism?: number; batchSize?: number; history?: boolean; reducedRigor?: boolean; };
  reducedRigorReason?: string;       // populated when composer was declined
}
```

---

## TargetSkill

```ts
interface TargetSkill {
  path: string;                       // absolute path to the skill directory
  name: string;                       // derived from frontmatter `name:`
  version: string;                    // semver; "0.0.0" if frontmatter omits
  archetype: Archetype;
  hasReferencesDir: boolean;
  hasRulesDir: boolean;
  hasScriptsDir: boolean;
  skillMdLineCount: number;
  skillMdContentHash: string;         // sha256 of SKILL.md
}

type Archetype = "orchestrator-with-subcommands"
              |  "single-purpose-rigid"
              |  "single-purpose-flexible"
              |  "reference-only"
              |  "unknown";           // detection-failed; rubric handles gracefully
```

---

## ComposerStatus

```ts
interface ComposerStatus {
  writingSkills: { installed: boolean; path?: string; };
  remoteSkillSecurityCheck: { installed: boolean; path?: string; };
  findSkills: { installed: boolean; path?: string; };
}
```

`installed` is `true` if a Glob finds the composer's `SKILL.md` in either the user's skills directory or the plugins cache.

---

## AuditResult

```ts
interface AuditResult {
  archetype: Archetype;
  patterns: PatternFinding[];
  weightedGpa: number;
  overallGrade: "A" | "B" | "C" | "D" | "F";
  scriptHygiene?: ScriptHygieneFinding[];   // present only when target.hasScriptsDir
  notes: string[];
}

interface PatternFinding {
  id: number;             // 1..10 (or higher if catalog extended)
  name: string;
  finding: "present" | "partial" | "absent" | "n/a";
  letter: "A" | "B" | "C" | "D" | "F" | null;
  weight: number;         // archetype-specific
  notes: string;
  fixHint?: string;       // file:line pointer for suggested fix
}
```

---

## ModernizePlan

```ts
interface ModernizePlan {
  basedOnAudit: AuditResult;
  edits: ProposedEdit[];
  diff: string;            // unified diff, all proposed changes concatenated
  approved: boolean;       // user gate result
}

interface ProposedEdit {
  file: string;
  action: "add-section" | "replace-section" | "extract-to-reference"
        | "add-frontmatter-key" | "split-monolith";
  rationale: string;       // which pattern this satisfies
  before: string;          // current content (or "" if new file)
  after: string;           // proposed content
}
```

---

## CreatePlan

```ts
interface CreatePlan {
  name: string;
  archetype: Archetype;
  description: string;
  triggerPhrases: string[];
  allowedTools: string[];
  rigidFlexible: { perSubcommand: Record<string, "rigid" | "flexible"> };
  subcommands?: string[];   // populated for orchestrator archetype
  composesWith: string[];
  scaffoldFiles: { path: string; content: string }[];
}
```

---

## RefreshPlan

```ts
interface RefreshPlan {
  sourcesQueried: ResearchSource[];
  findings: ResearchFinding[];
  conflicts: ConflictFinding[];
  proposedDiff: string;     // unified diff against rules/pattern-catalog.md + scoring-rubric.md
  approved: boolean;
}

interface ResearchSource {
  name: string;
  url: string;
  fetchedAt: string;        // ISO timestamp
  ok: boolean;
}

interface ResearchFinding {
  patternId?: number;       // existing pattern impacted, or null for new
  kind: "new-pattern" | "updated-detection" | "deprecated-pattern" | "rubric-shift";
  description: string;
  evidenceUrls: string[];
}

interface ConflictFinding {
  description: string;
  sources: { name: string; claim: string }[];
  recommendation?: string;  // populated only when one source clearly trumps
}
```

---

## BackupRecord

```ts
interface BackupRecord {
  skill: string;
  timestamp: string;        // ISO
  path: string;             // absolute path to backup dir
  status: "unverified" | "verified";
  subcommand: string;
  versionBefore: string;
}
```

Backup index lines (JSONL) are `BackupRecord` instances, append-only.

---

## Audit history entry

Each line of `<config>/.skill-modernizer/history.jsonl`:

```ts
interface HistoryEntry {
  ts: string;
  skill: string;
  action: "audit" | "score" | "modernize" | "migrate" | "create" | "refresh";
  score?: "A" | "B" | "C" | "D" | "F";
  ver: string;
}
```

---

## ScriptHygieneFinding

```ts
interface ScriptHygieneFinding {
  file: string;
  rule: "shebang" | "error-handling" | "secret-scan" | "exec-perm" | "deps-declared";
  status: "ok" | "warn" | "fail";
  note: string;
}
```

Loaded conditionally when `target.hasScriptsDir` is true.

---

## Why centralize this

Multiple subcommands operate on the same pieces (audit results feed modernize, modernize feeds re-audit, refresh re-runs audit on self). Consistent shapes prevent silent shape drift between subcommand references.
