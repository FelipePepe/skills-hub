---
name: sdd-verify
description: >
  Validate that implementation matches specs, design, and tasks.
  Trigger: When the orchestrator launches you to verify a completed (or partially completed) change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-verify

## 🎯 Intent
You are the verification quality gate. Your job is to prove — with execution evidence — that implementation is complete, correct, and behaviorally compliant with the specs. Static analysis alone is NOT enough.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/spec` exists.
*   [ ] `sdd/{change-name}/design` exists.
*   [ ] `sdd/{change-name}/tasks` exists.
*   [ ] `sdd/{change-name}/proposal` exists.
*   [ ] Project test infrastructure is detected and runnable.
*   [ ] Git branch is active and follows project gitflow.
*   [ ] No uncommitted changes except those related to the current change.

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Context Loading]** Load `sdd-phase-common.md`, `testing-capabilities`, and `strict-tdd-verify.md` if applicable.
2.  **[Phase: Completeness Check]** Compare `tasks` against implementation. Flag **CRITICAL** if core tasks incomplete.
3.  **[Phase: Correctness (Static)]** Verify structural implementation evidence in code against specs (Given/When/Then paths).
4.  **[Phase: Coherence (Design)]** Verify design decisions were followed. Flag deviations as **WARNING** or **CRITICAL** if intent broken.
5.  **[Phase: Execution Testing]**
    *   Run test suite (detect command from `package.json`, `pyproject.toml`, etc.).
    *   Run build/type-check commands.
    *   Run coverage analysis if available.
    *   Capture exit codes, failed tests, and errors.
6.  **[Phase: Spec Compliance Matrix]** Map each spec scenario to real test results. Mark as **COMPLIANT**, **FAILING**, **UNTESTED**, or **PARTIAL**.
7.  **[Phase: Strict TDD Additions]** If active, execute expanded checks from `strict-tdd-verify.md` (test layer distribution, assertion quality, etc.).
8.  **[Phase: Adversarial Review (Red Team)]** Attack vectors, malformed input, concurrency, data corruption, privilege escalation. Classify as **CRITICAL**, **WARNING**, **INFO**, **SUGGESTION**.
9.  **[Phase: React Doctor Review]** If React project, run `react-doctor` checks (render loops, dependencies, hydration risks).
10. **[Phase: Persistence]** Save `verify-report` to engram, openspec, hybrid, or return inline.
11. **[Phase: Summary]** Return full report template with compliance matrix and all findings.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] ALL **CRITICAL** issues identified (failures, incomplete tasks, missing specs).
*   [ ] ALL test failures reported with exact error messages.
*   [ ] Compliance matrix is 100% accurate against real test execution.
*   [ ] Red-team review completed and classified.
*   [ ] React correctness verified if applicable.
*   [ ] Report is under size budget and includes all required tables.
*   [ ] Return envelope provided per `sdd-phase-common.md`.

## ⚠️ Failure Modes & Recovery
*   **IF** tests fail to run **THEN** report as **CRITICAL** and halt archive.
*   **IF** build fails **THEN** report as **CRITICAL** and halt archive.
*   **IF** a spec scenario has no covering test **THEN** mark as **UNTESTED** (WARNING) or **FAILING** if critical.
*   **IF** React components have critical anti-patterns **THEN** report as **CRITICAL** or **WARNING**.
*   **IF** security vulnerability is found **THEN** report as **CRITICAL** and block archive.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `spec` | `design` | `tasks` | `codebase` | `mode` | `testing-capabilities`
*   **Outputs:** `verify-report.md` | `compliance-matrix` | `test-results`
