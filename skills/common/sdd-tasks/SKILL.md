---
name: sdd-tasks
description: >
  Break down a change into an implementation task checklist.
  Trigger: When the orchestrator launches you to create or update the task breakdown for a change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## Purpose

Create `tasks.md` from proposal, specs, and design. Concrete, actionable tasks organized by phase.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B and C.

| Mode | Write tasks to |
|---|---|
| `engram` | `sdd/{name}/tasks` in Engram |
| `openspec` | `openspec/changes/{name}/tasks.md` |
| `hybrid` | Both |
| `none` | Return only |

## Task Format

```markdown
# Tasks: {Change Title}

## Phase 1: {Name} (Foundation)
- [ ] 1.1 {Concrete action — file + change}

## Phase 2: {Name} (Core)
- [ ] 2.1 {Concrete action}
```

### Rules

Each task MUST be: **Specific** (file paths), **Actionable** (what to do), **Verifiable** (acceptance criteria), **Small** (one file or logical unit).

### Phase Convention

| Phase | Focus |
|---|---|
| 1: Foundation | Types, interfaces, DB changes, config |
| 2: Core | Business logic, main behavior |
| 3: Integration | Wiring, routes, UI |
| 4: Testing | Unit/integration/e2e |
| 5: Cleanup | Docs, dead code |

### Persist (MANDATORY)

topic_key: `sdd/{name}/tasks`, type: `architecture`

### Delivery Risk (Harness #18)

Estimate: total tasks, rough LOC, independent areas, DB migrations, public API changes → LOW | MODERATE | HIGH.

### Return Summary — per Section D of `sdd-phase-common.md`

## Rules

- ALWAYS reference concrete file paths
- Order by dependency (earlier phases don't depend on later)
- Each task completable in ONE session — split if too big
- Use hierarchical numbering: 1.1, 1.2, 2.1
- NEVER include vague tasks ("implement feature")
- Apply any `rules.tasks` from `openspec/config.yaml`
- **Size budget**: under 530 words, 1-2 lines per task

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
