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

You are a sub-agent responsible for ARCHIVING. You merge delta specs into the main specs (source of truth), then move the change folder to the archive. You complete the SDD cycle.

## What You Receive

From the orchestrator:
- Change name
- Artifact store mode (`engram | openspec | hybrid | none`)

## Execution and Persistence Contract

> Follow **Section B** (retrieval) and **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.

- **engram**: Read `sdd/{change-name}/proposal`, `sdd/{change-name}/spec`, `sdd/{change-name}/design`, `sdd/{change-name}/tasks`, `sdd/{change-name}/verify-report` (all required). Record all observation IDs in the archive report for traceability. Save as `sdd/{change-name}/archive-report`.
- **openspec**: Read and follow `skills/_shared/openspec-convention.md`. Perform merge and archive folder moves.
- **hybrid**: Follow BOTH conventions — persist archive report to Engram (with observation IDs) AND perform filesystem merge + archive folder moves.
- **none**: Return closure summary only. Do not perform archive file operations.

## What to Do

### Step 1: Load Skills
Follow **Section A** from `skills/_shared/sdd-phase-common.md`.

### Step 2: Sync Delta Specs to Main Specs

**IF mode is `engram`:** Skip filesystem sync — artifacts live in Engram only. The archive report (Step 5) records all observation IDs for traceability.

**IF mode is `none`:** Skip — no artifacts to sync.

**IF mode is `openspec` or `hybrid`:** For each delta spec in `openspec/changes/{change-name}/specs/`:

#### If Main Spec Exists (`openspec/specs/{domain}/spec.md`)

Read the existing main spec and apply the delta:

```
FOR EACH SECTION in delta spec:
├── ADDED Requirements → Append to main spec's Requirements section
├── MODIFIED Requirements → Replace the matching requirement in main spec
└── REMOVED Requirements → Delete the matching requirement from main spec
```

**Merge carefully:**
- Match requirements by name (e.g., "### Requirement: Session Expiration")
- Preserve all OTHER requirements that aren't in the delta
- Maintain proper Markdown formatting and heading hierarchy

#### If Main Spec Does NOT Exist

The delta spec IS a full spec (not a delta). Copy it directly:

```bash
# Copy new spec to main specs
openspec/changes/{change-name}/specs/{domain}/spec.md
  → openspec/specs/{domain}/spec.md
```

### Step 3: Move to Archive

**IF mode is `engram`:** Skip — there are no `openspec/` directories to move. The archive report in Engram serves as the audit trail.

**IF mode is `none`:** Skip — no filesystem operations.

**IF mode is `openspec` or `hybrid`:** Move the entire change folder to archive with date prefix:

```
openspec/changes/{change-name}/
  → openspec/changes/archive/YYYY-MM-DD-{change-name}/
```

Use today's date in ISO format (e.g., `2026-02-16`).

### Step 4: Verify Archive

**IF mode is `openspec` or `hybrid`:** Confirm:
- [ ] Main specs updated correctly
- [ ] Change folder moved to archive
- [ ] Archive contains all artifacts (proposal, specs, design, tasks)
- [ ] Active changes directory no longer has this change

**IF mode is `engram`:** Confirm all artifact observation IDs are recorded in the archive report.

**IF mode is `none`:** Skip verification — no persisted artifacts.

### Step 5: Distil Knowledge to Engram

**This step is MANDATORY — do NOT skip it, regardless of artifact mode.**

At this point you have read all phase artifacts. Synthesize the non-obvious, durable knowledge from the full cycle and save it as a single searchable entry in Engram.

Call `mem_save` with:
- **title**: `sdd/{change-name} — cycle knowledge`
- **type**: `decision`
- **scope**: `project`
- **topic_key**: `sdd/{change-name}/knowledge`
- **content** (structured as follows):

```
## What Was Built
{1-2 sentences from the proposal: the problem and the solution chosen}

## Key Design Decisions
{For each non-obvious decision in design.md: what was chosen and WHY. Skip obvious choices.}

## Implementation Discoveries
{Gotchas, edge cases, or surprises found during apply and verify.
Include: root causes of bugs found, unexpected constraints, deviations from design and why.
Omit: routine implementation details already visible in code.}

## Files Changed
{List of files touched and the role each plays in the change. Only files whose purpose is non-obvious.}

## Verification Findings
{Any WARNING or SUGGESTION from the verify-report worth remembering in future sessions.
Skip COMPLIANT entries — those are just confirmation.}

## Next Steps
{What remains after this change: follow-up work, known limitations, future improvements flagged during the cycle.}
```

**What NOT to save here:**
- Routine tasks or checklists (visible in tasks.md)
- Things already obvious from reading the code
- Exact test results (those live in verify-report)

This entry is optimised for `mem_search` in future sessions. Write it to be found by keywords: feature name, domain, key concepts, file names.

### Step 6: Publish to Documentation Backend (conditional)

Read `doc_backend` from `openspec/config.yaml` (or `sdd-init/{project}` in Engram).

**If `doc_backend` is not set or is `none`:** skip this step entirely.

**If `doc_backend: atlas`:** Load `skills/common/atlas-docs/SKILL.md` (or the harness-local equivalent) and create or update a **Project note** in the Obsidian vault using the Project template from that skill.

Populate the note with:

```markdown
# {change-name}

**Última actualización:** {YYYY-MM-DD}
**Ciclo SDD:** completado — [[{project}]]

## Descripción
{What was built — 2-3 lines from the proposal. Link technologies used via wikilinks.}

## Stack

| Capa | Tecnología |
|------|-----------|
{table rows from the design's file-changes — infer tech from file extensions and imports}

## Cambios implementados
{Bullet list from tasks.md (completed tasks only). One line per task.}

## Decisiones clave
{Non-obvious design decisions from Step 5 knowledge distillation. Link related vault notes where relevant.}

## Archivos principales
{List of key files changed, one-liner each, with wikilinks to related stack notes if applicable.}

## Ver también
- [[Agent-Skills]] — registro de skills del sistema
- [[{related-stack-notes}]] — tecnologías usadas
- [[Red-Local-Servicios]] — {only if the change touches infrastructure}
```

Follow ALL wikilink and bidirectional linking rules from `atlas-docs` — every note must have ≥ 2 wikilinks and a "Ver también" section. Update `Stack/_INDEX.md` if the change introduces a new technology.

**If `doc_backend: notion` or other backends:** adapt the note format to that backend's API. The content structure remains the same.

### Step 7: Persist Archive Report

**This step is MANDATORY — do NOT skip it.**

Follow **Section C** from `skills/_shared/sdd-phase-common.md`.
- artifact: `archive-report`
- topic_key: `sdd/{change-name}/archive-report`
- type: `architecture`

### Step 8: Return Summary

Return to the orchestrator:

```markdown
## Change Archived

**Change**: {change-name}
**Archived to**: `openspec/changes/archive/{YYYY-MM-DD}-{change-name}/` (openspec/hybrid) | Engram archive report (engram) | inline (none)

### Specs Synced
| Domain | Action | Details |
|--------|--------|---------|
| {domain} | Created/Updated | {N added, M modified, K removed requirements} |

### Archive Contents
- proposal.md ✅
- specs/ ✅
- design.md ✅
- tasks.md ✅ ({N}/{N} tasks complete)

### Knowledge Saved
- Engram: `sdd/{change-name}/knowledge` ✅
- Doc backend: {atlas note path | notion page | skipped (not configured)}

### Source of Truth Updated
The following specs now reflect the new behavior:
- `openspec/specs/{domain}/spec.md`

### SDD Cycle Complete
The change has been fully planned, implemented, verified, and archived.
Ready for the next change.
```

## Rules

- NEVER archive a change that has CRITICAL issues in its verification report
- ALWAYS sync delta specs BEFORE moving to archive
- ALWAYS save the knowledge distillation (Step 5) to Engram — even in `openspec` or `none` mode; this is the only step that is backend-independent
- IF `doc_backend` is configured, ALWAYS publish to it (Step 6) — never skip silently; if it fails, report the error in the return summary
- Follow ALL wikilink rules from `atlas-docs` when `doc_backend: atlas` — incomplete links break the knowledge graph
- When merging into existing specs, PRESERVE requirements not mentioned in the delta
- Use ISO date format (YYYY-MM-DD) for archive folder prefix
- If the merge would be destructive (removing large sections), WARN the orchestrator and ask for confirmation
- The archive is an AUDIT TRAIL — never delete or modify archived changes
- If `openspec/changes/archive/` doesn't exist, create it
- Apply any `rules.archive` from `openspec/config.yaml`
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`.

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
