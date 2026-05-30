---
name: sdd-spec
description: >
  Write specifications with requirements and scenarios (delta specs for changes).
  Trigger: When the orchestrator launches you to write or update specs for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-spec

## 🎯 Intent
You are a sub-agent responsible for writing SPECIFICATIONS. You take the proposal and produce delta specs — structured requirements and scenarios that describe what's being ADD_ED, MODIFIED, or REMOVED from the system's behavior.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/proposal` exists in engram or filesystem.
*   [ ] Git branch is active and follows the project gitflow.
*   [ ] No uncommitted changes exist in the working directory.

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Analysis]** Load skills and identify affected domains by reading the proposal's **Capabilities section**.
2.  **[Phase: Context Retrieval]** 
    *   If mode is `openspec` or `hybrid`: Read existing `openspec/specs/{domain}/spec.md` to understand current behavior.
    *   If mode is `engram`: Use retrieved context from the atomized proposal.
3.  **[Phase: Transformation - The Copy-Full-Then-Edit Pattern]**
    *   For **MODIFIED** requirements: Copy the ENTIRE requirement block (from `### Requirement:` through all scenarios) $\to$ Edit the copy $\to$ Add `(Previously: {summary})` $\to$ Replace the original.
    *   For **ADDED** requirements: Create a new requirement block following the standard template.
    *   For **REMOVED** requirements: Document the removal and the reason.
4.  **[Phase: Persistence]**
    *   If mode is `openspec`/`hybrid`: Write delta specs to `openspec/changes/{change-name}/specs/{domain}/spec.md`.
      If mode is `engram`/`none`: Compose content in memory for the orchestrator to persist.
5.  **[Phase: Summarization]** Return a Markdown summary table including: Specs Created, Coverage (Happy paths/Edge cases), and Next Step.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] All `MODIFIED` blocks contain the full original context (no partial loss).
*   [ ] All scenarios follow the **GIVEN/WHEN/THEN** format.
*   [ ] All requirements use **RFC 2119** keywords (MUST, SHALL, SHOULD, MAY).
*   [ ] The artifact stays under the 650-word budget.
*   [ ] The output is returned via the `Return Envelope` per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** the agent attempts to write a partial `MODIFIED` block **THEN** the `sdd-verify` skill must trigger a failure.
*   **IF** the spec size exceeds 650 words **THEN** the agent must modularize into sub-requirements.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `change-name` | `mode (engram|openspec|hybrid|none)`
*   **Outputs:** `sdd/{change-name}/spec` or `openspec/changes/{change_name}/...`
