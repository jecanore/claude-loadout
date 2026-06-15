# MaintainState — Session-Only State Schema

Conceptual session-only state. Not persisted to disk (except `last-sync-marker`, see below). Built up across steps and read by later steps and by composing skills.

```typescript
interface MaintainState {
  // Convention detection (rules/scaffolds.md)
  sourceDir: string;             // 'src/' | 'app/' | 'lib/' | 'packages/'
  packageManager: string;        // 'npm' | 'yarn' | 'pnpm' | 'bun' | 'pip' | 'poetry' | 'cargo' | 'go' | 'composer'
  testRunner: string | null;     // 'vitest' | 'jest' | 'mocha' | 'pytest' | 'rspec' | null
  language: 'typescript' | 'javascript' | 'python' | 'ruby' | 'rust' | 'go' | 'php' | 'mixed';
  framework: string | null;      // 'next' | 'nuxt' | 'remix' | 'express' | 'django' | 'rails' | etc.
  buildCommand: string | null;
  isMonorepo: boolean;

  // Artifact detection
  artifacts: {
    gitnexus: boolean;
    docsSpec: boolean;
    childClaudeMd: string[];     // paths to existing child CLAUDE.md files
    academy: boolean;
    memoryMd: boolean;
    changelog: boolean;
    rootClaudeMd: boolean;
    envExample: boolean;
    lockfiles: string[];         // ['package-lock.json', 'pnpm-lock.yaml']
    lintConfig: string | null;   // '.eslintrc.json' | 'ruff.toml' | etc.
  };

  // Audit-first full run state (rules/freshness-audit.md)
  freshnessRange: {
    kind: 'last-sync' | 'feature-branch' | 'main-history' | 'dirty-tree';
    baseRef: string | null;
    headRef: string;
    includesUncommitted: boolean;
  };
  artifactFreshness: {
    artifact: string;            // 'CLAUDE.md' | '.env.example' | 'GitNexus Index' | etc.
    exists: boolean;
    status: 'missing' | 'current' | 'stale' | 'unknown' | 'not-applicable';
    evidence: string;
    recommendedAction: string | null;
    priority: 'high' | 'medium' | 'optional' | 'not-needed';
  }[];
  recommendedActions: {
    subcommand: string;           // 'sync' | 'env' | 'reindex' | etc.
    priority: 'high' | 'medium' | 'optional' | 'not-needed';
    evidence: string;
    prechecked: boolean;
  }[];

  // Sync state
  changedFiles: string[];
  changes: {
    type: string;                // change-detection.md categories
    file: string;
    line: number;
    description: string;
  }[];
  gaps: {
    file: string;
    section: string;
    type: 'GAP' | 'STALE' | 'OK';
    detail: string;
  }[];

  // Refs state
  oldPatterns: string[];
  newContext: string;
  discoveries: {
    file: string;
    line: number;
    match: string;
    tier: number;                // 1..6 from priority-tiers.md
  }[];

  // New 2026-05 subcommand state
  lockDrift: {
    lockfile: string;
    issue: 'manifest-mismatch' | 'integrity-fail' | 'dual-lockfile' | 'stale-resolution';
    detail: string;
  }[];
  envDrift: {
    varName: string;
    seenIn: string[];            // file:line refs from runtime code
    inExample: boolean;
  }[];
  brokenLinks: {
    file: string;
    line: number;
    target: string;
    reason: 'missing-file' | 'missing-anchor' | 'http-error' | 'fragment-not-found';
    httpStatus?: number;
  }[];
  secretHits: {
    file: string;
    line: number;
    rule: string;                // 'aws-access-key' | 'github-token' | 'jwt' | etc.
    match: string;               // truncated and partially masked
    falsePositiveLikelihood: 'low' | 'medium' | 'high';
  }[];
  deadCode: {
    tool: string;                // 'ts-prune' | 'knip' | 'vulture' | etc.
    file: string;
    symbol: string;
    confidence: 'high' | 'medium' | 'low';
  }[];
  lintDrift: {
    rule: string;
    addedAt: string;             // commit sha or config diff ref
    affectedFiles: string[];
    autoFixAvailable: boolean;
  }[];

  // Results aggregation
  modifiedFiles: string[];
  results: {
    step: string;
    status: 'done' | 'skipped' | 'failed';
    detail: string;
  }[];
}
```

## Persistence

The only persisted artifact is `.claude/maintain/last-sync` — written after a successful `sync`:

```
{
  "lastSyncAt": "2026-05-07T14:32:11Z",
  "lastSyncSha": "abc1234",
  "lastSyncFiles": ["CLAUDE.md", "README.md", ".env.example", "CHANGELOG.md"]
}
```

Future `sync` runs use `lastSyncSha..HEAD` as the default range.

## Read by Other Skills

Skills that compose with `/maintain` may read `state.results[]` to know what ran (e.g., `/gsd-ship` checking that docs are synced before opening a PR).
