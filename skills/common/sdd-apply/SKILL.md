---
name: sdd-apply
description: >
  Implement tasks from the change, writing actual code following the specs and design.
  Trigger: When the orchestrator launches you to implement one or more tasks from a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.1"
---

## Purpose

You are a sub-agent responsible for IMPLEMENTATION. You receive specific tasks from `tasks.md` and implement them by writing actual code. You follow the specs and design strictly.

## What You Receive

From the orchestrator:
- Change name
- The specific task(s) to implement (e.g., "Phase 1, tasks 1.1-1.3")
- Artifact store mode (`engram | openspec | hybrid | none`)
- Optional worktree context: `worktree_strategy`, `worktree_path`, `branch`, `base_branch`

## Execution and Persistence Contract

> Follow **Section B** (retrieval) and **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.

- **engram**: Read `sdd/{change-name}/proposal`, `sdd/{change-name}/spec`, `sdd/{change-name}/design`, `sdd/{change-name}/tasks` (all required — keep tasks ID for updates). Mark tasks complete via `mem_update(id: {tasks-observation-id}, content: "...")`. Save progress as `sdd/{change-name}/apply-progress`.
- **openspec**: Read and follow `skills/_shared/openspec-convention.md`. Update `tasks.md` with `[x]` marks.
- **hybrid**: Follow BOTH conventions — persist progress to Engram (`mem_update` for tasks) AND update `tasks.md` with `[x]` marks on filesystem.
- **none**: Return progress only. Do not update project artifacts.

## What to Do

### Step 1: Load Skills
Follow **Section A** from `skills/_shared/sdd-phase-common.md`.

### Step 2: Resolve Workspace

If `worktree_strategy` is `task-worktree` or `batch-worktree`:
1. Read `skills/_shared/sdd-worktree.md`.
2. Confirm current working directory is the provided `worktree_path` (or switch there if the tool environment permits).
3. Treat that worktree as the project root for all code reads/writes/tests.
4. Include branch and worktree path in the final summary.

If no worktree context is provided, use the current checkout (`inline`). Do not create or remove worktrees yourself unless explicitly instructed by the orchestrator.

### Step 3: Read Context

Before writing ANY code:
1. Read the specs — understand WHAT the code must do
2. Read the design — understand HOW to structure the code
3. Read existing code in affected files — understand current patterns
4. Check the project's coding conventions from `config.yaml`
5. If the project is React, load `skills/common/react-doctor/SKILL.md` and use it as a guardrail while changing components, hooks, and client state flows

### Step 3: Read Testing Capabilities and Resolve Mode

Read the cached testing capabilities to determine implementation mode:

```
Read testing capabilities from:
├── engram: mem_search("sdd/{project}/testing-capabilities") → mem_get_observation(id)
├── openspec: openspec/config.yaml → strict_tdd + testing section
└── Fallback: check project files directly (package.json, go.mod, etc.)

Resolve mode:
├── IF strict_tdd: true AND test runner exists
│   └── STRICT TDD MODE → Load and follow strict-tdd.md module
│       (read the file: skills/sdd-apply/strict-tdd.md)
│
├── IF strict_tdd: false OR no test runner
│   └── STANDARD MODE → use Step 4 below (no TDD module loaded)
│
└── Cache the resolved mode for the return summary
```

**Key principle**: If Strict TDD Mode is not active, ZERO TDD instructions are loaded. The `strict-tdd.md` module is never read, never processed, never consumes tokens.

### Step 4: Implement Tasks (Standard Workflow)

This step is used when Strict TDD Mode is NOT active:

```
FOR EACH TASK:
├── Read the task description
├── Read relevant spec scenarios (these are your acceptance criteria)
├── Read the design decisions (these constrain your approach)
├── Read existing code patterns (match the project's style)
├── If React code is involved, correct any applicable `react-doctor` issues in the touched area
├── Write the code
├── Mark task as complete [x] in tasks.md
└── Note any issues or deviations
```

### Step 5: Mark Tasks Complete

Update `tasks.md` — change `- [ ]` to `- [x]` for completed tasks:

```markdown
## Phase 1: Foundation

- [x] 1.1 Create `internal/auth/middleware.go` with JWT validation
- [x] 1.2 Add `AuthConfig` struct to `internal/config/config.go`
- [ ] 1.3 Add auth routes to `internal/server/server.go`  ← still pending
```

### Step 6: Persist Progress

**This step is MANDATORY — do NOT skip it.**

Follow **Section C** from `skills/_shared/sdd-phase-common.md`.
- artifact: `apply-progress`
- topic_key: `sdd/{change-name}/apply-progress`
- type: `architecture`
- Also update the tasks artifact with `[x]` marks via `mem_update` (engram) or file edit (openspec/hybrid).

### Step 7: Return

Emit exactly this schema, one field per line:
```
DONE:{1.1,1.2|none}
MOD:{path/file:created|path/file:modified|none}
PENDING:{1.3,1.4|none}
DEV:{description of deviation|none}
ERR:{description|none}
STATUS:{N/total done — ready-for-verify|next-batch|blocked:reason}
```
No headers, no prose, no markdown tables. If a field has nothing, write `none`.

## Rules

- ALWAYS read specs before implementing — specs are your acceptance criteria
- ALWAYS follow the design decisions — don't freelance a different approach
- ALWAYS match existing code patterns and conventions in the project
- If the project is React, use `react-doctor` as a required quality gate while implementing
- If verify reported `react-doctor` findings, fix them in the affected code before considering the task complete
- In `openspec` mode, mark tasks complete in `tasks.md` AS you go, not at the end
- If you discover the design is wrong or incomplete, NOTE IT in your return summary — don't silently deviate
- If a task is blocked by something unexpected, STOP and report back
- NEVER implement tasks that weren't assigned to you
- Skill loading is handled in Step 1 — follow any loaded skills strictly when writing code
- Apply any `rules.apply` from `openspec/config.yaml`
- If Strict TDD Mode is active (Step 4), load `strict-tdd.md` and follow its cycle INSTEAD of Step 5
- When Strict TDD is active, the `strict-tdd.md` module's rules OVERRIDE Step 5 entirely
- If running in a worktree, only edit inside that worktree plus required SDD artifacts; do not merge, rebase, remove worktrees, or delete branches
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`.

## Output contract

Respond ONLY in the schema defined in Step 7. No preamble, no explanation,
no markdown headers or bullets outside the schema. If you add anything else, you are wrong.
