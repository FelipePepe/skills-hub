---
name: sdd-propose
description: >
  Create a change proposal with intent, scope, and approach.
  Trigger: When the orchestrator launches you to create or update a proposal for a change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## Purpose

Produce a structured `proposal.md` from exploration analysis or direct user input.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B and C.

| Mode | Save as |
|---|---|
| `engram` | `sdd/{name}/proposal` |
| `openspec` | `openspec/changes/{name}/proposal.md` |
| `hybrid` | Both |
| `none` | Return only |

## Process

1. **Load skills** — Section A
2. **Create change directory** (openspec/hybrid only)
3. **Read existing specs** (openspec/hybrid only)
4. **Write proposal** — Intent, Scope (in/out), Capabilities (New + Modified — CONTRACT with sdd-spec), Approach, Affected Areas (table), Risks, Rollback Plan, Dependencies, Success Criteria
5. **Persist** (MANDATORY) — topic_key: `sdd/{name}/proposal`, type: `architecture`
6. **Return summary** — per Section D of `sdd-phase-common.md`

## Rules

- In `openspec` mode, ALWAYS create `proposal.md`
- If exists → read first, then update
- Keep concise — thinking tool, not a novel
- EVERY proposal MUST have rollback plan + success criteria
- Use concrete file paths in Affected Areas
- **ALWAYS fill Capabilities section** — research existing specs first
- New Capabilities → `openspec/specs/<name>/spec.md`; Modified → delta spec
- If nothing changes at spec level → write "None" under both
- Apply any `rules.proposal` from `openspec/config.yaml`
- **Size budget**: under 450 words, bullets + tables over prose

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
