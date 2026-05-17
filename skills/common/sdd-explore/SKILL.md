---
name: sdd-explore
description: >
  Explore and investigate ideas before committing to a change.
  Trigger: When the orchestrator launches you to think through a feature, investigate the codebase, or clarify requirements.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## Purpose

Investigate codebase, compare approaches, return structured analysis. Only research — create `exploration.md` only if tied to a named change.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B and C.

| Mode | Save as |
|---|---|
| `engram` | `sdd/{name}/explore` |
| `openspec` | Follow openspec convention |
| `hybrid` | Both |
| `none` | Return only |

## Process

1. **Load skills** — Section A from `sdd-phase-common.md`
2. **Understand request** — new feature? bug fix? refactor?
3. **Investigate codebase** — entry points → related functionality → tests → patterns → dependencies
4. **Analyze options** — if multiple approaches, compare with pros/cons/complexity table
5. **Persist** (MANDATORY when named change) — topic_key: `sdd/{name}/explore`, type: `architecture`
6. **Return structured analysis** — Current State, Affected Areas, Approaches (1-2 per option), Recommendation, Risks, Ready for Proposal

## Rules

- ONLY file you may create: `exploration.md` in change folder
- DO NOT modify existing code
- ALWAYS read real code
- Keep analysis CONCISE
- If not enough info → say so; if request too vague → say what's needed
- Return envelope per Section D of `sdd-phase-common.md`

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
