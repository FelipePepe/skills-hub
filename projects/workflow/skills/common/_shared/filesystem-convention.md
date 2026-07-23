# Filesystem Artifact Convention (shared across all SDD skills)

`openspec` mode is backed by the real OpenSpec CLI (`@fission-ai/openspec`, ≥1.6, Node ≥20.19). `sdd-init` bootstraps it with `pnpm dlx @fission-ai/openspec@latest init --tools claude`; `sdd new`/`sdd apply`/`sdd archive` then delegate to its `/opsx:propose`, `/opsx:apply`, `/opsx:archive` commands instead of hand-writing these files. The layout below is what the CLI produces — read it to know where artifacts live, not as something to write by hand. `sdd-verify` has no CLI equivalent (the default schema has no `verify` artifact) and keeps writing `verify-report.md` itself.

## Directory Structure

```
sdd/
├── config.yaml              <- Project-specific SDD config
├── specs/                   <- Source of truth (main specs)
│   └── {domain}/
│       └── spec.md
└── changes/                 <- Active changes
    ├── archive/             <- Completed changes (YYYY-MM-DD-{change-name}/)
    └── {change-name}/       <- Active change folder
        ├── state.yaml       <- DAG state (survives compaction)
        ├── exploration.md   <- (optional) from sdd-explore
        ├── proposal.md      <- from sdd-propose
        ├── specs/           <- from sdd-spec
        │   └── {domain}/
        │       └── spec.md  <- Delta spec
        ├── design.md        <- from sdd-design
        ├── tasks.md         <- from sdd-tasks (updated by sdd-apply)
        └── verify-report.md <- from sdd-verify
```

## state.yaml Worktree Fields (optional)

When the orchestrator uses git worktrees, store enough state to resume after compaction:

```yaml
worktrees:
  strategy: inline | task-worktree | batch-worktree
  base_branch: develop
  canonical_branch: sdd/<change>
  tasks:
    "1.1":
      branch: sdd/<change>/1-1
      path: ../<repo>.sdd/<change>/1-1
      status: active | integrated | abandoned
```

See `skills/_shared/sdd-worktree.md` for policy.

## Artifact File Paths

| Skill | Creates / Reads | Path |
|-------|----------------|------|
| orchestrator | Creates/Updates | `sdd/changes/{change-name}/state.yaml` |
| sdd-init | Creates | `sdd/config.yaml`, `sdd/specs/`, `sdd/changes/`, `sdd/changes/archive/` |
| sdd-explore | Creates (optional) | `sdd/changes/{change-name}/exploration.md` |
| sdd-propose | Creates | `sdd/changes/{change-name}/proposal.md` |
| sdd-spec | Creates | `sdd/changes/{change-name}/specs/{domain}/spec.md` |
| sdd-design | Creates | `sdd/changes/{change-name}/design.md` |
| sdd-tasks | Creates | `sdd/changes/{change-name}/tasks.md` |
| sdd-apply | Updates | `sdd/changes/{change-name}/tasks.md` (marks `[x]`) |
| sdd-verify | Creates | `sdd/changes/{change-name}/verify-report.md` |
| sdd-archive | Moves | `sdd/changes/{change-name}/` → `sdd/changes/archive/YYYY-MM-DD-{change-name}/` |
| sdd-archive | Updates | `sdd/specs/{domain}/spec.md` (merges deltas into main specs) |

## Reading Artifacts

```
Proposal:   sdd/changes/{change-name}/proposal.md
Specs:      sdd/changes/{change-name}/specs/  (all domain subdirectories)
Design:     sdd/changes/{change-name}/design.md
Tasks:      sdd/changes/{change-name}/tasks.md
Verify:     sdd/changes/{change-name}/verify-report.md
Config:     sdd/config.yaml
Main specs: sdd/specs/{domain}/spec.md
```

## Writing Rules

- Always create the change directory before writing artifacts
- If a file already exists, READ it first and UPDATE it (don't overwrite blindly)
- If the change directory already exists with artifacts, the change is being CONTINUED
- Use `sdd/config.yaml` `rules` section for project-specific constraints per phase

## Config File Reference

```yaml
# sdd/config.yaml
schema: spec-driven

context: |
  Tech stack: {detected}
  Architecture: {detected}
  Testing: {detected}
  Style: {detected}

rules:
  proposal:
    - Include rollback plan for risky changes
  specs:
    - Use Given/When/Then for scenarios
    - Use RFC 2119 keywords (MUST, SHALL, SHOULD, MAY)
  design:
    - Include sequence diagrams for complex flows
    - Document architecture decisions with rationale
  tasks:
    - Group by phase, use hierarchical numbering
    - Keep tasks completable in one session
  apply:
    - Follow existing code patterns
    tdd: false           # Set to true to enable RED-GREEN-REFACTOR
    test_command: ""
  verify:
    test_command: ""
    build_command: ""
    coverage_threshold: 0
  archive:
    - Warn before merging destructive deltas
```

## Archive Structure

When archiving, the change folder moves to:
```
sdd/changes/archive/YYYY-MM-DD-{change-name}/
```

Use today's date in ISO format. The archive is an AUDIT TRAIL — never delete or modify archived changes.
