---
name: sdd
description: >
  SDD orchestrator — Spec-Driven Development full cycle. Manages phases, gates,
  execution mode, delegation, sub-agent isolation, skill digestion, and artifact
  persistence. Trigger: "sdd init", "sdd new <feature>", "sdd explore", "sdd status",
  "sdd continue", "sdd apply", "sdd verify", "sdd archive", "sdd onboard",
  or any SDD cycle command.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  version: "3.0"
  harness: agnostic
---

## Role

COORDINATOR only — you do NOT execute. Detect phase, enforce gates, launch correct sub-agents, inject compact rules.

## Delegation Decision

| Scope | Action |
|---|---|
| Read ≤ 3 files to decide | Inline |
| Read 4+ files to explore | Delegate to sub-agent |
| Write one file, know what | Inline |
| Write across files or with analysis | Delegate |
| Run tests/builds | Delegate |
| Ambiguous/architectural/risky | Full SDD cycle |

## Lite Path

For bounded changes meeting ALL criteria: ≤ 3 files, single concern, not security-sensitive, unambiguous.

Process: analyze inline → apply inline → verify inline → `mem_save` (lite archive). No sub-agents for planning.

## Execution Mode

Ask user ONCE on first `/sdd-new`/`/sdd-ff`/`/sdd-continue`:
- `interactive` (default) — pause after each phase
- `auto` — run all phases, show final result only

## Persistence Modes

| Mode | Storage |
|---|---|
| `engram` | Memory backend (default) |
| `openspec` | `openspec/` in filesystem |
| `hybrid` | Both |
| `none` | Ephemeral |

## Phase DAG

```
init → explore → propose → spec ─┐
                      └→ design ─┤
          └→ tasks ─→ apply → verify → archive
```

**This is a contract. The orchestrator STOPS if a gate fails.**

| Phase | Gate |
|---|---|
| `propose` | `proposal` exists |
| `spec` | `spec` exists with Requirements |
| `design` | `design` exists with File Changes |
| `tasks` | tasks generated and persisted |
| `apply` | 0 tasks pending/in_progress |
| `verify` | `verify_pass = true` |
| `archive` | `verify_pass = true` |

## Artifact Dependencies

| Phase | Reads (required) | Writes |
|---|---|---|
| `explore` | nothing | `explore` |
| `propose` | `explore` (opt) | `proposal` |
| `spec` | `proposal` (req) | `spec` |
| `design` | `proposal` (req) | `design` |
| `tasks` | `spec` + `design` (req) | `tasks` |
| `apply` | `tasks` + `spec` + `design` | `apply-progress` |
| `verify` | `spec` + `tasks` | `verify-report` |
| `archive` | all artifacts | `archive-report` |

If required artifact missing → STOP and report what's missing.

## Result Contract

Every sub-agent MUST return:

```markdown
**Status**: success | partial | blocked
**Summary**: 1-3 sentences
**Artifacts**: list of keys/paths written
**Next**: recommended next phase or "none"
**Risks**: risks found or "None"
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

## State

```sql
CREATE TABLE IF NOT EXISTS sdd_cycle (
  feature       TEXT NOT NULL PRIMARY KEY,
  phase         TEXT NOT NULL DEFAULT 'propose',
  artifact_mode TEXT NOT NULL DEFAULT 'engram',
  exec_mode     TEXT NOT NULL DEFAULT 'interactive',
  started_at    INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  updated_at    INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  verify_pass   INTEGER NOT NULL DEFAULT 0
);
```

Engram topic key: `sdd/{change-name}/state`

## Commands

| Command | Sub-agent skill | Phase |
|---|---|---|
| `sdd init` | `sdd-init` | `init` |
| `sdd explore <topic>` | `sdd-explore` | `explore` |
| `sdd new <change>` | lite: inline / full: propose→spec→design→tasks | — |
| `sdd status` | (inline) | — |
| `sdd continue` | gate check + next skill | — |
| `sdd apply [task-id]` | `sdd-apply` | `apply` |
| `sdd verify` | `sdd-verify` + `red-team-offensive` | `verify` |
| `sdd archive` | `sdd-archive` | `done` |

## Process Per Command

### `sdd init`
Invoke `sdd-init`. Cache testing capabilities and stack.
```sql
INSERT OR IGNORE INTO sdd_cycle (feature, phase, artifact_mode, exec_mode)
VALUES ('{project}', 'init', '{mode}', '{exec_mode}');
```

### `sdd new <change>`
1. Classify as Lite (inline) or Full (sub-agents)
2. Ask execution mode if not set
3. Insert state row
4. Full path: invoke `sdd-propose` → `sdd-spec` → `sdd-design` → `sdd-tasks`
5. Interactive mode: pause + confirm between phases

### `sdd status`
```sql
SELECT feature, phase, artifact_mode, exec_mode, verify_pass,
       datetime(started_at/1000, 'unixepoch'), datetime(updated_at/1000, 'unixepoch')
FROM sdd_cycle ORDER BY updated_at DESC LIMIT 1;
```

### `sdd continue`
Check gate. If fails → STOP, report missing. If passes → advance + invoke next skill.

### `sdd apply [task-id]`
Gate: phase must be `apply` or `tasks`. Invoke `sdd-apply`.

### `sdd verify`
Gate: all tasks done. Invoke `sdd-verify` then `red-team-offensive`. If both pass:
```sql
UPDATE sdd_cycle SET phase='verify', verify_pass=1 WHERE feature='{feature}';
```

### `sdd archive`
Gate: `verify_pass=1`. Invoke `sdd-archive`.
```sql
UPDATE sdd_cycle SET phase='done' WHERE feature='{feature}';
```

## Skill Injection

At session start, load skill registry. Before each sub-agent launch: match by code context (file extensions) + task context (actions), inject Compact Rules as `## Project Standards (auto-resolved)`, max 5 blocks. **NEVER pass raw SKILL.md paths.**

After every delegation, check Skill Resolution. If not `injected` → re-read registry, inject in ALL subsequent delegations, warn user.

## Sub-Agent Isolation

Each sub-agent gets: task instructions, artifact references (keys/paths, not inline content), compact rules, persistence mode.

Sub-agents do NOT get: orchestrator conversation, raw SKILL.md paths, inline artifact content.

**One sub-agent per phase.**

## Model Routing Hints

| Phase | Preferred | Reason |
|---|---|---|
| orchestrator | architect | Decisions |
| explore | coder/fast | Structural |
| propose | architect | Architecture |
| spec | coder/fast | Writing |
| design | architect | Architecture |
| tasks | coder/fast | Mechanical |
| apply | coder/specialized | Implementation |
| verify | architect | Validation |
| archive | fast/cheap | Close |

## Golden Rules

1. Never skip a gate — explain what's missing
2. One task at a time in apply
3. State is source of truth
4. Gate fails → report exactly what's missing
5. `red-team-offensive` mandatory in verify
6. Inject Project Standards into every sub-agent
7. Check Skill Resolution Feedback every delegation
