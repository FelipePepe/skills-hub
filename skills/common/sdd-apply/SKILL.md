---
name: sdd-apply
description: >
  Implement code changes following the design and specification.
  Trigger: When the orchestrator launches you to implement the change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-apply

## 🎯 Intent
Execute the actual implementation of the code changes, ensuring that the code adheres to the provided design, specification, and the core philosophy of Security-First, TDD, and Clean Code.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] `sdd/{change-name}/spec` is loaded and understood.
*   [ 	] `sdd/{change-name}/design` is loaded and understood.
*   [ ] Presence of TDD infrastructure (test framework) is verified.
*   [ ] The implementation occurs on a branch following the project's gitflow.

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Setup]** Ensure the environment is ready and the test suite can be run.
2.  **[Phase: Red]** Write/Update the test case that covers the new or modified requirement from the `sdd-spec`. Run the test and confirm it **FAILS**.
3.  **[Phase: Green]** Write the minimum amount of code necessary to make the test **PASS**.
4.  **[Phase: Refactor]** Clean up the code, applying Design Patterns, ensuring the **Boy Scout Rule** (leave it cleaner than you found it), and maintaining **Security-by-Design**.
5.  **[Phase: Verification]** Run the full test suite to ensure no regressions were introduced.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] All tests related to the change are **PASSING**.
*   [ ] Code adheres to **Security-First** (no new vulnerabilities) and **Security-by-Default** principles.
*   [ ] Code implements the design patterns defined in `sdd-design`.
*   [ ] No new technical debt or "dirty" code was introduced (Boy Scout Rule).

## ⚠️ Failure Modes & Recovery
*   **IF** the test fails after the "Green" phase **THEN** re-evaluate the implementation against the `sdd-spec`.
*   **IF** a security vulnerability is detected during implementation **THEN** halt and revert to the `sdd-design` phase.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `sdd-spec` | `sdd-design` | `test-suite`
*   **Outputs:** Modified source files | Updated test files | Test execution report
