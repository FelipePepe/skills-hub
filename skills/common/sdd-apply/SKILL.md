---
name: sdd-apply
description: >
  Implement tasks from the change, writing actual code following the specs and design.
  Trigger: When the orchestrator launches you to implement one or more tasks from a change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "3.1"
---

## Harnesses

**#11 — Strict TDD**: If `strict_tdd: true` and test runner exists → red→green→triangulate→refactor. Tests before code, no exceptions.

**#13 — Apply Progress Continuity**: First action — read `apply-progress`, resume from where it stopped. Never re-implement what's done.

## Purpose

Implement specific tasks from `tasks.md` following specs and design strictly.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B (retrieval) and C (persistence).

| Mode | Action |
|---|---|
| `engram` | Read all artifacts from Engram. Update via `mem_update`. |
| `openspec` | Update `tasks.md` with `[x]` marks |
| `hybrid` | Both engram + filesystem |
| `none` | Return progress only |

## Process

0. **Continuity check** — read `apply-progress`, resume from first pending task
1. **Load skills** — Section A from `sdd-phase-common.md`
2. **Read context** — specs → design → existing code → conventions
3. **Resolve TDD mode** — from testing capabilities
   - `strict_tdd: true` + runner → load `strict-tdd.md`
   - otherwise → standard mode (ZERO TDD instructions loaded)
4. **Implement tasks** — one at a time, mark complete `[x]`
5. **Persist progress** — topic_key: `sdd/{name}/apply-progress`, type: `architecture` (MANDATORY)
6. **Return summary** — per Section D of `sdd-phase-common.md`

## Rules

- ALWAYS read specs before implementing
- ALWAYS follow the design — don't freelance
- ALWAYS match existing code patterns
- If React → use `react-doctor` as quality gate
- If design is wrong → NOTE it, don't silently deviate
- If blocked → STOP and report back
- NEVER implement unassigned tasks
- Apply any `rules.apply` from `openspec/config.yaml`

## Model routing hints

- preferred agent: coder
- preferred model: ollama/qwen3-coder:30b
