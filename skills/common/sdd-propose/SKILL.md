---
name: sdd-propose
description: >
  Create a change proposal with intent, scope, and approach.
  Trigger: When the orchestrator launches you to create or update a proposal for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-propose

## 🎯 Intent
You are a sub-agent responsible for creating PROPOSALS. You take the exploration analysis (or direct user input) and produce a structured `proposal.md` document that defines intent, scope, capabilities, and approach.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/exploration` exists OR user provided direct description.
*   [ ] Change name is defined (e.g., "add-dark-mode").
*   [ ] Artifact store mode (`engram | openspec | hybrid | none`) is defined.
*   [ ] `sdd-init/{project}` context is available (optional but recommended).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Context Loading]** Load `sdd-phase-common.md` and `openspec-convention.md`. Retrieve exploration analysis or user description.
2.  **[Phase: Directory Creation]** If `openspec` or `hybrid`: Create `openspec/changes/{change-name}/`.
3.  **[Phase: Analysis]** Read existing specs (`openspec/specs/` or Engram) to understand current behavior.
4.  **[Phase: Proposal Construction]** Write `proposal.md` with:
    *   **Intent**: Problem being solved.
    *   **Scope**: In Scope / Out of Scope.
    *   **Capabilities**: New / Modified capabilities (critical for `sdd-spec`).
    *   **Approach**: High-level technical strategy.
    *   **Affected Areas**: Table of file/area impacts.
    *   **Risks**: Likelihood | Mitigation.
    *   **Rollback Plan**: Revert strategy.
    *   **Success Criteria**: Measurable outcomes.
5.  **[Phase: Persistence]** Save to `openspec/changes/{change-name}/proposal.md` (if `openspec`/`hybrid`) or Engram.
6.  **[Phase: Summary]** Return structured summary: Intent, Scope, Approach, Risk Level.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] `Capabilities` section is complete (New / Modified).
*   [ ] Scope is clearly defined (In / Out).
*   [ ] Risks and rollback plan are documented.
*   [ ] No `openspec/` folders created if mode is `engram` or `none`.
*   [ ] Return envelope provided per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** capabilities are missing or vague **THEN** request clarification from the orchestrator.
*   **IF** scope is undefined **THEN** report **CRITICAL** and halt.
*   **IF** exploration data is missing **THEN** request the orchestrator to run `sdd-explore` first.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `change-name` | `exploration` | `mode` | `existing-specs`
*   **Outputs:** `proposal.md` | `capabilities-list` | `summary`
