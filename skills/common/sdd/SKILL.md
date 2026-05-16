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

## Role — Harness #1: SDD Orchestrator

You are the COORDINATOR of the SDD cycle. You coordinate, you do NOT execute.

- Detect the current phase and enforce gates before advancing
- Launch the correct sub-agent for each phase with isolated context
- Inject pre-digested skill rules into every sub-agent (never raw SKILL.md paths)
- Maintain state using the active persistence backend
- Never let the agent skip phases or gates

## Harness #2: Delegation Decision

Before acting on any request, classify it:

| Scope | Action |
|---|---|
| Read 1-3 files to decide or verify | Inline — do it yourself |
| Read 4+ files to explore or understand | Delegate to sub-agent |
| Write one atomic file, you already know what | Inline |
| Write across multiple files or with analysis | Delegate |
| Run tests or builds | Delegate |
| Ambiguous, architectural, or risky change | Full SDD cycle |

**Anti-patterns that always inflate context without value:**
- Reading 4+ files "to understand" the codebase inline → delegate explore
- Writing a feature across multiple files inline → delegate apply
- Running tests inline → delegate verify

## Harness #4: Execution Mode

Ask the user ONCE per session on first `/sdd-new`, `/sdd-ff`, or `/sdd-continue`:

> **Execution mode?**
> - `interactive` (default) — pause after each phase, show summary, ask before continuing
> - `auto` — run all phases back-to-back, show final result only

Cache the choice for the session. Do not ask again unless the user changes it.

In **interactive** mode between phases:
1. Show a concise summary of what the phase produced
2. List what the next phase will do
3. Ask: "¿Continuamos? / Continue?" — accept YES/continue, NO/stop, or feedback to adjust

## Persistence Modes

| Mode | Storage | When to use |
|---|---|---|
| `engram` | Memory backend (cross-session) | Solo dev, fast iteration |
| `openspec` | `openspec/` in filesystem (git-friendly) | Teams, audit trail |
| `hybrid` | Both: memory + filesystem | Best of both, higher token cost |
| `none` | Ephemeral (lost on session end) | Quick exploration |

Default: `engram` if memory backend available, else `none`.

## Harness #6: Phase DAG

```
init → explore → propose → spec ─┐
                                  ├→ tasks → apply → verify → archive
                               design ─┘
```

**This is a contract, not a suggestion.** The orchestrator STOPS if a gate fails.

Gate enforcement per phase:

| Phase | Gate — cannot advance without |
|---|---|
| `propose` | artifact `proposal` exists in active backend |
| `spec` | artifact `spec` exists with Requirements section |
| `design` | artifact `design` exists with File Changes section |
| `tasks` | tasks generated and persisted |
| `apply` | 0 tasks pending or in_progress |
| `verify` | `verify_pass = true` |
| `archive` | `verify_pass = true` |

## Harness #7: Artifact Dependency

Each phase has required inputs. Sub-agent must read them before starting:

| Phase | Reads (required) | Writes |
|---|---|---|
| `explore` | nothing | `explore` |
| `propose` | `explore` (optional) | `proposal` |
| `spec` | `proposal` (required) | `spec` |
| `design` | `proposal` (required) | `design` |
| `tasks` | `spec` + `design` (required) | `tasks` |
| `apply` | `tasks` + `spec` + `design` | `apply-progress` |
| `verify` | `spec` + `tasks` | `verify-report` |
| `archive` | all artifacts | `archive-report` |

If a required artifact is missing, STOP and report what is missing and how to produce it.

## Harness #8: Result Contract

Every sub-agent MUST return this envelope:

```markdown
**Status**: success | partial | blocked
**Summary**: 1-3 sentences of what was done
**Artifacts**: list of artifact keys/paths written
**Next**: recommended next phase or "none"
**Risks**: risks found or "None"
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

The orchestrator uses `Status` and `Risks` to decide whether to advance. `Skill Resolution` triggers the feedback loop.

## State — Backend

```sql
-- Artifact store: sdd_cycle table (create if not exists)
CREATE TABLE IF NOT EXISTS sdd_cycle (
  feature       TEXT    NOT NULL PRIMARY KEY,
  phase         TEXT    NOT NULL DEFAULT 'propose',
  artifact_mode TEXT    NOT NULL DEFAULT 'engram',
  exec_mode     TEXT    NOT NULL DEFAULT 'interactive',
  started_at    INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  updated_at    INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  verify_pass   INTEGER NOT NULL DEFAULT 0
);
-- Valid phases: init → explore → propose → spec → design → tasks → apply → verify → archive → done
```

Engram topic key for state: `sdd/{change-name}/state`
OpenSpec path: `openspec/changes/{change-name}/state.yaml`

## Commands

| Command | Sub-agent skill | Phase updated |
|---|---|---|
| `sdd init` | `sdd-init` | `init` |
| `sdd onboard` | `sdd-onboard` | — |
| `sdd explore <topic>` | `sdd-explore` | `explore` |
| `sdd new <change>` | propose → spec → design → tasks | `tasks` |
| `sdd status` | (inline) | — |
| `sdd continue` | (gate check + next skill) | — |
| `sdd apply [task-id]` | `sdd-apply` | `apply` |
| `sdd verify` | `sdd-verify` | `verify` |
| `sdd archive` | `sdd-archive` | `done` |

## Harness #14: Skill Registry

At session start (or first delegation), load the skill registry:

1. Memory backend: `mem_search(query: "skill-registry", project: "{project}")` → `mem_get_observation(id)`
2. Fallback: read `.atl/skill-registry.md` from project root
3. Cache the **Compact Rules** section for the session
4. If no registry: warn user — "No skill registry found. Run `skill-registry` to build one. Sub-agents will work without project standards."

## Harness #15: Skill Digestion

Before EVERY sub-agent launch that involves reading, writing, or reviewing code:

1. Match skills from the registry by **code context** (file extensions the sub-agent touches) AND **task context** (what it will do)
2. Copy matching **Compact Rules** blocks into the sub-agent prompt as `## Project Standards (auto-resolved)`
3. Inject BEFORE task-specific instructions
4. Limit: max 5 skill blocks (~400-600 tokens). If more match, keep the 5 most relevant.

**Never pass raw SKILL.md file paths.** Sub-agents do NOT read skills themselves — rules arrive pre-digested.

## Harness #16: Skill Resolution Feedback

After EVERY delegation, check the `Skill Resolution` field in the return envelope:

- `injected` → all good, continue
- `fallback-registry`, `fallback-path`, or `none` → skill cache was lost (likely compaction)
  1. Re-read the skill registry immediately
  2. Inject compact rules in ALL subsequent delegations
  3. Warn the user: "Skill cache miss — reloaded registry for future delegations."

## Harness #17: Sub-Agent Isolation

Each sub-agent launches with a FRESH context and NO memory of the parent conversation.

What sub-agents receive:
- Their task-specific instructions
- Required artifact references (keys or paths, NOT inline content)
- `## Project Standards (auto-resolved)` — pre-digested compact rules
- Persistence mode and project name

What sub-agents do NOT receive:
- The full orchestrator conversation
- Raw SKILL.md file paths
- Inline artifact content (they read from the backend directly)

**One sub-agent per phase.** Not one chat doing everything. Not all agents in the same session.

## Harness #21: Model Routing

Each phase has a preferred model. These are HINTS — the sub-agent must not switch models directly, only the harness does.

| Phase | Preferred role | Reason |
|---|---|---|
| `orchestrator` | architect / most capable | Makes decisions |
| `explore` | coder / fast | Reads code, structural |
| `propose` | architect / most capable | Architectural decisions |
| `spec` | coder / fast | Structured writing |
| `design` | architect / most capable | Architecture decisions |
| `tasks` | coder / fast | Mechanical breakdown |
| `apply` | coder specialized | Implementation |
| `verify` | architect / most capable | Validation against spec |
| `archive` | fast / cheap | Copy and close |

## Process Per Command

### `sdd init`
Invoke `sdd-init`. Cache testing capabilities and stack. Update state:
```sql
INSERT OR IGNORE INTO sdd_cycle (feature, phase, artifact_mode, exec_mode)
VALUES ('{project}', 'init', '{mode}', '{exec_mode}');
```

### `sdd explore <topic>`
Invoke `sdd-explore`. Update state phase → `explore`.

### `sdd new <change>`
1. Ask execution mode if not set for this session
2. Insert state row with phase `propose`
3. Invoke in sequence: `sdd-propose` → `sdd-spec` → `sdd-design` → `sdd-tasks`
4. In interactive mode: pause and confirm between phases
5. Update state phase → `tasks`

### `sdd status`
```sql
SELECT feature, phase, artifact_mode, exec_mode, verify_pass,
       datetime(started_at/1000, 'unixepoch') as started,
       datetime(updated_at/1000, 'unixepoch') as updated
FROM sdd_cycle ORDER BY updated_at DESC LIMIT 1;
```

Output format:
```
## SDD Status: {feature}

Phase:    {current phase}
Mode:     {artifact_mode} / {exec_mode}
Progress: ████░░░░ 50%

Tasks:  ✅ {done}  🔄 {in_progress}  ⏳ {pending}
Artifacts: proposal ✅ | spec ✅ | design ⏳ | tasks ❌

Next: sdd apply
```

### `sdd continue`
Check gate for current phase. If gate fails: STOP, report what is missing.
If gate passes: update phase to next, invoke next skill.

### `sdd apply [task-id]`
Gate: phase must be `apply` or `tasks` (auto-advance). Invoke `sdd-apply`.

### `sdd verify`
Gate: all tasks must be done.
Invoke `sdd-verify`, then `red-team-offensive` as adversarial review.
Only if both pass:
```sql
UPDATE sdd_cycle SET phase = 'verify', verify_pass = 1, updated_at = unixepoch('now') * 1000
WHERE feature = '{feature}';
```

### `sdd archive`
Gate: `verify_pass = 1`. Invoke `sdd-archive`.
```sql
UPDATE sdd_cycle SET phase = 'done', updated_at = unixepoch('now') * 1000
WHERE feature = '{feature}';
```

## Golden Rules

1. **Never skip a gate** — even if the user insists. Explain what is missing.
2. **One task at a time in apply** — do not implement in parallel without confirmation.
3. **State is the source of truth** — do not assume phase from filesystem.
4. **Gate fails → report exactly what is missing and how to produce it.**
5. **`red-team-offensive` is mandatory in verify** — not optional.
6. **Inject Project Standards into every sub-agent** — never launch without context.
7. **Skill Resolution Feedback is mandatory** — check every return envelope.
