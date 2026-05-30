---
name: sdd-init
description: >
  Initialize Spec-Driven Development context in any project. Detects stack, conventions, testing capabilities, and bootstraps the active persistence backend.
  Trigger: When user wants to initialize SDD in a project, or says "sdd init", "iniciar sdd", "openspec init".
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-init

## 🎯 Intent
You initialize SDD context in a project: detect stack and conventions, detect testing capabilities, resolve Strict TDD mode, and bootstrap the active persistence backend. You are an executor for this phase.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] Project root directory is accessible.
*   [ ] Git repository exists (if project uses git).
*   [ ] User has provided the change name or project context.
*   [ ] The active persistence mode (`engram | openspec | hybrid | none`) is defined by the orchestrator.

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Context Detection]** Read the project and identify:
    *   Tech stack (`package.json`, `go.mod`, `pyproject.toml`, etc.).
    *   Existing conventions (linters, test frameworks, CI).
    *   Architecture patterns already in use.
2.  **[Phase: Testing Capability Detection]** Detect all testing infrastructure:
    *   Test runner (framework + command).
    *   Test layers (unit / integration / E2E).
    *   Coverage command (if available).
    *   Quality tools (linter, type checker, formatter).
3.  **[Phase: TDD Resolution]** Resolve Strict TDD mode:
    *   Priority: system/config marker → `openspec/config.yaml` → default `true` (if runner exists) → force `false` (if none).
4.  **[Phase: Persistence Bootstrap]**
    *   If `openspec` or `hybrid`: Create `openspec/`, `openspec/config.yaml`, `openspec/specs/`, `openspec/changes/archive/`.
    *   If `engram` or `hybrid`: Persist to Engram (project context, testing capabilities).
5.  **[Phase: Skill Registry]** Scan and register user/project-level skills. Write `.atl/skill-registry.md`.
6.  **[Phase: Report]** Return structured summary: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] All testing capabilities detected and persisted (Engram and/or filesystem).
*   [ ] Strict TDD mode resolved and documented.
*   [ ] `openspec/config.yaml` created with concise context if mode includes filesystem.
*   [ ] Skill registry updated and persisted.
*   [ ] No placeholder specs created (real detection only).
*   [ ] Return envelope provided per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** project has no test runner and Strict TDD is requested **THEN** disable TDD and report as warning.
*   **IF** `openspec/` already exists **THEN** report and let orchestrator decide updates (do not overwrite).
*   **IF** project files cannot be read **THEN** report **CRITICAL** and halt.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `project-root` | `mode (engram|openspec|...)` | `orchestrator-config`
*   **Outputs:** `openspec/config.yaml` | `skill-registry.md` | `testing-capabilities` | `project-context`
