---
name: sdd-archive
description: >
  Sync delta specs to main specs and archive a completed change.
  Trigger: When the orchestrator launches you to archive a change after implementation and verification.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-archive

## 🎯 Intent
You complete the SDD cycle by merging delta specs into the main specs (source of truth), moving the change folder to the archive, and recording the closure.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/verify-report` exists and has NO **CRITICAL** issues.
*   [ ] `sdd/{change-name}/proposal` exists.
*   [ ] `sdd/{change-name}/spec` exists.
*   [ ] `sdd/{change-name}/design` exists.
*   [ ] `sdd/{change-name}/tasks` exists.
*   [ ] Git branch is clean (all changes committed or stashed).
*   [ ] Change name matches the active branch (if applicable).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Context Loading]** Load `sdd-phase-common.md`, `openspec-convention.md`, and verify all artifacts.
2.  **[Phase: Sync Deltas to Main Specs]**
    *   If `openspec` or `hybrid`: For each delta in `changes/{name}/specs/`:
        *   **ADDED:** Append to main spec.
        *   **MODIFIED:** Replace matching requirement in main spec.
        *   **REMOVED:** Delete matching requirement from main spec.
        *   Preserve all unrelated requirements.
    *   If `engram` or `none`: Skip filesystem sync (handled via engram IDs).
3.  **[Phase: Archive Move]**
    *   If `openspec` or `hybrid`: Move `openspec/changes/{name}/` to `openspec/changes/archive/YYYY-MM-DD-{name}/`.
    *   If `engram` or `none`: Skip (log only).
4.  **[Phase: Verify Archive]**
    *   Confirm main specs updated correctly.
    *   Confirm folder moved to archive with date prefix.
    *   Confirm archive contains all artifacts (proposal, specs, design, tasks, verify-report).
5.  **[Phase: Persistence]** Save `archive-report` to engram, openspec, hybrid, or return inline.
6.  **[Phase: Summary]** Return closure summary: specs synced, archive location, SDD cycle complete.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] Main specs reflect ALL changes from the delta (no data loss).
*   [ ] Archive folder created with correct ISO date prefix.
*   [ ] All artifacts preserved in archive.
*   [ ] Active changes directory no longer contains the change.
*   [ ] Archive report includes all observation IDs (if engram).
*   [ ] SDD cycle is officially closed and traceable.
*   [ ] Return envelope provided per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** verification report has **CRITICAL** issues **THEN** abort and alert (no archive).
*   **IF** conflict detected during merge (e.g., deleted sections) **THEN** WARN and request manual confirmation.
*   **IF** archive folder creation fails **THEN** report **CRITICAL** and halt.
*   **IF** missing artifacts **THEN** report **CRITICAL** and halt.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `proposal` | `spec` | `design` | `tasks` | `verify-report` | `mode`
*   **Outputs:** `archive-report.md` | `updated-main-specs` | `archived-folder`
