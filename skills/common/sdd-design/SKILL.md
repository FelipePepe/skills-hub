---
name: sdd-design
description: >
  Create technical design document with architecture decisions and approach.
  Trigger: When the orchestrator launches you to write or update the technical design for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-design

## 🎯 Intent
You are a sub-agent responsible for TECHNICAL DESIGN. You take the proposal and specs, then produce a `design.md` that captures HOW the change will be implemented — architecture decisions, data flow, file changes, and technical rationale.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/proposal` exists in engram or filesystem.
*   [ ] `sdd/{change-name}/spec` exists (required for dependency-aware design).
*   [ ] Git branch is active and follows the project's gitflow.
*   [ ] Codebase is readable (filesystem or engram context available).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Context Loading]** Load `sdd-phase-common.md` and read proposal + spec.
2.  **[Phase: Codebase Analysis]** Read the actual code that will be affected:
    *   Entry points and module structure.
    *   Existing patterns and conventions.
    *   Dependencies and interfaces.
    *   Test infrastructure.
3.  **[Phase: Design Transformation]** Create `design.md` adhering to the standard format:
    *   **Technical Approach** (mapping to proposal/spec).
    *   **Architecture Decisions** (Choice | Alternatives | Rationale).
    *   **Data Flow** (with ASCII diagrams).
    *   **File Changes** (Create | Modify | Delete table).
    *   **Interfaces / Contracts** (code blocks).
    *   **Testing Strategy** (unit | integration | e2e table).
    *   **Migration / Rollout** (if required).
4.  **[Phase: Persistence]** Save artifact to `openspec/changes/{change-name}/design.md` or engram.
5.  **[Phase: Summary]** Return a structured response: Approach, Key Decisions, Files Affected, Testing Strategy, Open Questions.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] Every decision MUST have a rationale (the "why").
*   [ ] Concrete file paths are used, not abstract descriptions.
*   [ ] Design follows the project's ACTUAL patterns and conventions.
*   [ ] Open questions are explicitly flagged if they BLOCK the design.
*   [ ] Artifact is under 800 words (architecture decisions as tables).
*   [ ] Return envelope is provided per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** the codebase cannot be read **THEN** fail immediately and report the missing dependency.
*   **IF** open questions block the design **THEN** explicitly state them and halt the transition to `sdd-tasks`.
*   **IF** the artifact exceeds 800 words **THEN** modularize decisions into sub-sections.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `proposal` | `spec` | `codebase` | `mode (engram|openspec|...)`
*   **Outputs:** `design.md` | `summary-table`
