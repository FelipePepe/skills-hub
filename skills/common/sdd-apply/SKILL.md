---
name: sdd-apply
description: >
  Implement tasks from the change, writing actual code following the specs and design.
  Generates per-task diffs (delta tracking) for code review and HyperFrames video.
  Trigger: When the orchestrator launches you to implement one or more tasks from a change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "3.2"
---

## Harnesses

**#11 — Strict TDD**: If `strict_tdd: true` and test runner exists → red→green→triangulate→refactor. Tests before code, no exceptions.

**#13 — Apply Progress Continuity**: First action — read `apply-progress`, resume from where it stopped. Never re-implement what's done.

**#15 — Delta Tracking (HyperFrames video)**: After implementing each task, capture the diff as a self-contained snapshot and persist a reference to Engram. The orchestrator can later read these diffs to compose HyperFrames video with before/after frames.

## Purpose

Implement specific tasks from `tasks.md` following specs and design strictly. Track per-task diffs for HyperFrames video generation.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B (retrieval) and C (persistence).

| Mode | Action |
|---|---|
| `engram` | Read from Engram. Update via `mem_update`. Deltas → filesystem |
| `openspec` | Update `tasks.md` with `[x]` marks. Deltas → filesystem |
| `hybrid` | Both engram + filesystem |
| `none` | Return progress only. Deltas → inline |

## Process

### Step 0: Continuity check

Read `apply-progress`, resume from first pending task. Log: "Resuming from task {N.M} — {N} tasks already complete."

### Step 1: Load skills

Section A from `sdd-phase-common.md`.

### Step 2: Read context

specs → design → existing code → conventions. If React → load `react-doctor`.

### Step 3: Resolve TDD mode

- `strict_tdd: true` + runner → load `strict-tdd.md`
- otherwise → standard mode (ZERO TDD instructions)

### Step 4: Create delta directory (openspec/hybrid only)

```
openspec/changes/{name}/deltas/
├── {phase-slug}/          ← e.g. "foundation", "core", "integration"
│   ├── 1.1_middleware.diff
│   └── 1.2_config.diff
└── {phase-slug}/
    └── 2.1_auth.diff
```

Create the `deltas/` directory if it doesn't exist. Phase slug comes from `tasks.md` phase names (e.g., "Phase 1: Foundation" → "foundation").

### Step 5: Implement tasks (one at a time)

For each task:
1. Read the task description and relevant spec scenarios (acceptance criteria)
2. Read design decisions (constraints)
3. Read existing code patterns (match style)
4. Implement the change
5. If React → fix `react-doctor` issues in touched area
6. Mark complete `[x]` in `tasks.md`
7. **Capture delta** (MANDATORY):
   - Generate git-style unified diff of files changed by this task
   - Write to `openspec/changes/{name}/deltas/{phase-slug}/{task-id}.diff`
   - Include file headers: `diff --git a/... b/...`
   - Each delta must be self-contained (shows full before→after for the files touched)
   - If engram mode: write deltas to filesystem anyway, record reference in Engram:
     `mem_save(title: "sdd/{name}/deltas/{task-id}", type: "artifact-ref", content: "openspec/changes/{name}/deltas/{phase-slug}/{task-id}.diff")`
   - If none mode: include delta inline in the return summary

### Step 6: Persist progress (MANDATORY)

topic_key: `sdd/{name}/apply-progress`, type: `architecture`

Update tasks artifact with `[x]` marks via `mem_update` (engram) or file edit (openspec/hybrid).

### Step 7: Return summary

```markdown
## Implementation Progress

**Change**: {name}
**Mode**: {Strict TDD | Standard}
**Deltas**: {N} files changed across {M} phases

### Completed Tasks
- [x] {task 1.1 description}

### Delta Files
| Phase | Task | Files Changed | Delta Path |
|-------|--|-----|-----|
| Foundation | 1.1 | 2 | `deltas/foundation/1.1_middleware.diff` |
| Core | 2.1 | 3 | `deltas/core/2.1_auth.diff` |

### Deviations from Design
{or "None — implementation matches design."}

### Issues Found
{or "None."}

### Remaining Tasks
- [ ] {next task}

### Status
{N}/{total} tasks complete. {Ready for next batch / Ready for verify / Blocked by X}
```

## Rules

- ALWAYS read specs before implementing
- ALWAYS follow the design — don't freelance
- ALWAYS match existing code patterns
- If React → use `react-doctor` as quality gate
- If design is wrong → NOTE it, don't silently deviate
- If blocked → STOP and report back
- NEVER implement unassigned tasks
- ALWAYS capture per-task deltas — critical for HyperFrames video generation
- Each delta must be a self-contained unified diff (full before→after)
- Apply any `rules.apply` from `openspec/config.yaml`
- If Strict TDD active, load `strict-tdd.md` and follow its cycle INSTEAD of Step 5

## Model routing hints

- preferred agent: coder
- preferred model: ollama/qwen3-coder:30b
