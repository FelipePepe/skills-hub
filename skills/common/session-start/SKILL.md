---
name: session-start
description: >
  Always-active session initialization protocol. Reads engram memory, verifies GitFlow branch state, and checks SDD context at the start of every session.
  Trigger: Always active — load in every session automatically.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: session-start

## 🎯 Intent
Execute the mandatory initialization protocol at the beginning of every session to ensure context, state, and safety before any work begins.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] Session is starting (new message from user).
*   [ ] Git hooks path is accessible (`~/.copilot/hooks/...`).
*   [ ] Engram service is available (if configured).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Hook Execution]** Run `session-start.sh` to capture initial git and session state.
2.  **[Phase: GitFlow Check]** Run `gitflow-check.sh`.
    *   **IF** exit code != 0 **THEN** STOP and prompt for branch creation.
    *   **IF** no git repo **THEN** initialize git (`main` → `develop` → `feature/<name>`).
    *   **IF** branch is correct **THEN** proceed.
3.  **[Phase: SDD Context Check]** Check for `openspec/config.yaml`.
    *   **IF** exists: Check for active changes (`openspec/changes/`). Resume if found.
    *   **IF** not found: Skip SDD steps.
4.  **[Phase: Engram Load]** Call `engram-mem_context` with inferred project ID.
5.  **[Phase: Work Discovery]** Look for pending tasks (`in_progress`, `blocked`, unfinished items).
6.  **[Phase: Report]** Summarize to user:
    *   Current branch.
    *   Active SDD change (if any) with phase.
    *   Pending engram work (if any).
    *   Ask for next action.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] Git branch is valid before any code edit.
*   [ ] SDD change is resumed or initialized if active.
*   [ ] Engram context is loaded.
*   [ ] User is informed of pending work.
*   [ ] No step is skipped (even for quick requests).

## ⚠️ Failure Modes & Recovery
*   **IF** git is uninitialized **THEN** initialize it as part of the workflow.
*   **IF** engram is unavailable **THEN** continue with local context.
*   **IF** no SDD context and user requests feature **THEN** prompt to run `sdd new` or override.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `session-start` | `git-state` | `engram-context`
*   **Outputs:** `status-report` | `branch-state` | `next-action-prompt`
