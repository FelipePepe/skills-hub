---
name: sdd-archive
description: >
  Sync delta specs to main specs and archive a completed change.
  Trigger: When the orchestrator launches you to archive a change after implementation and verification.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## Purpose

Merge delta specs into main specs, move change to archive, distill knowledge to Engram. Complete the SDD cycle.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B (retrieval) and C (persistence).

| Mode | Action |
|---|---|
| `engram` | Read all artifacts from Engram. Skip filesystem sync. |
| `openspec` | Read from openspec, merge deltas, move to archive |
| `hybrid` | Both engram + openspec |
| `none` | Return summary only, no filesystem ops |

## Process

1. **Load skills** — Section A from `sdd-phase-common.md`
2. **Sync delta specs** — For each delta spec:
   - `engram`/`none`: skip filesystem sync
   - `openspec`/`hybrid`: for each section in delta → ADDED→append, MODIFIED→replace, REMOVED→delete
3. **Move to archive** — `openspec/changes/{name}/` → `openspec/changes/archive/YYYY-MM-DD-{name}/`
4. **Verify archive** — confirm specs updated, folder moved, all artifacts present
5. **Distil knowledge to Engram** (MANDATORY) — topic_key: `sdd/{name}/knowledge`, type: `decision`
6. **Publish to doc backend** (if `doc_backend` configured) — atlas: create Obsidian project note via `atlas-docs`
7. **Persist archive report** — topic_key: `sdd/{name}/archive-report`, type: `architecture`
8. **Return summary** — per Section D of `sdd-phase-common.md`

## Knowledge Distillation (MANDATORY)

Synthesize durable, non-obvious knowledge: What was built, key design decisions, implementation discoveries, files changed, verification findings, next steps.

**What NOT to save:** routine tasks, obvious details, exact test results.

## Rules

- NEVER archive a change with CRITICAL verification issues
- ALWAYS sync deltas BEFORE moving to archive
- ALWAYS save knowledge distillation to Engram (even in `none` mode)
- ALWAYS publish to doc backend if configured
- Follow all wikilink rules from `atlas-docs` when `doc_backend: atlas`
- PRESERVE requirements not mentioned in the delta
- Use ISO date format for archive prefix
- Archive is an AUDIT TRAIL — never delete or modify
- Apply any `rules.archive` from `openspec/config.yaml`

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
