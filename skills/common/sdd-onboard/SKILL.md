---
name: sdd-onboard
description: >
  Guided end-to-end walkthrough of the SDD workflow using the real codebase.
  Trigger: When the orchestrator launches you to onboard a user through the full SDD cycle.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-onboard

## 🎯 Intent
You guide the user through a complete SDD cycle — from exploration to archive — using their actual codebase. This is a real change with real artifacts, designed to teach by doing.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] User has consented to an onboarding session.
*   [ ] Artifact store mode (`engram | openspec | hybrid | none`) is defined.
*   [ ] Project codebase is accessible.
*   [ ] Git repository exists (if applicable).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Welcome & Analysis]**
    *   Greet user and explain the onboarding goal.
    *   Scan codebase for a small, low-risk improvement opportunity (criteria: <1h scope, real value, spec-worthy).
    *   Present 2-3 options to the user for selection.
2.  **[Phase: Explore (Narrated)]**
    *   Narrate the `sdd-explore` behavior: investigate the chosen area, explain current state, identify changes.
    *   Present findings and confirm before proceeding.
3.  **[Phase: Propose (Narrated)]**
    *   Narrate `sdd-propose`: create `proposal.md` (Intent, Scope, Capabilities, Approach).
    *   Show and review the proposal with the user.
4.  **[Phase: Specs (Narrated)]**
    *   Narrate `sdd-spec`: write delta specs (Given/When/Then scenarios).
    *   Explain the testable scenarios.
5.  **[Phase: Design (Narrated)]**
    *   Narrate `sdd-design`: create technical approach, architecture decisions, file changes.
6.  **[Phase: Tasks (Narrated)]**
    *   Narrate `sdd-tasks`: break down into actionable checklist (phased).
7.  **[Phase: Apply (Narrated)]**
    *   Narrate `sdd-apply`: implement code with TDD (Red → Green → Refactor).
    *   Explain each step to the user.
8.  **[Phase: Verify (Narrated)]**
    *   Narrate `sdd-verify`: run tests, check compliance, red-team review.
    *   Show compliance matrix and findings.
9.  **[Phase: Archive (Narrated)]**
    *   Narrate `sdd-archive`: sync specs, move to archive.
    *   Confirm completion.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] All artifacts created: `proposal`, `spec`, `design`, `tasks`, `verify-report`, `archive-report`.
*   [ ] User understands each phase and its purpose.
*   [ ] Change is fully implemented and merged to the main specs.
*   [ ] All tests pass and security review is clear.
*   [ ] SDD cycle is closed and traceable.

## ⚠️ Failure Modes & Recovery
*   **IF** user cannot select an option **THEN** suggest a default small improvement.
*   **IF** a phase fails (e.g., verification fails) **THEN** stop and explain the failure to the user, then retry or abort.
*   **IF** codebase is too complex for onboarding **THEN** recommend a simpler target.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `mode` | `project-context` | `user-suggestion`
*   **Outputs:** `full-sdd-cycle-artifacts` | `onboarding-summary`
