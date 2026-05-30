---
name: session-end
description: >
  Session cleanup and memory consolidation protocol. Runs at the end of every task to summarize work, persist findings, and close the session cleanly.
  Trigger: Always active — execute when a task or request is fully completed.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "3.0"
---

# 🛡️ Execution Contract: session-end

## 🎯 Intent
Execute the mandatory cleanup and memory persistence protocol at the end of every completed task or session.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] Task or session is complete (user request fulfilled).
*   [ ] Git hooks path is accessible.
*   [ ] Engram service is available (if configured).

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Git Context]** Run `session-end.sh` to capture git state (branch, changes, commits).
2.  **[Phase: Session Summary]** Call `engram-mem_session_summary` with:
    *   **Goal**: One-sentence summary.
    *   **Instructions**: User preferences/constraints discovered.
    *   **Discoveries**: Technical findings or learnings.
    *   **Accomplished**: ✅ Completed tasks | 🔲 Carried-over tasks.
    *   **Relevant Files**: Key files modified.
3.  **[Phase: Close Session]** Call `engram-mem_session_end` to release resources.
4.  **[Phase: Report]** Confirm session closure to user.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] Session summary is persisted to Engram.
*   [ ] All 🔲 items are explicitly noted for next session.
*   [ ] Git context is captured.
*   [ ] Session is marked as closed.
*   [ ] No step is skipped (even for short sessions).

## ⚠️ Failure Modes & Recovery
*   **IF** no work was done but session is ending **THEN** still close session with empty summary.
*   **IF** engram is unavailable **THEN** note it and skip Engram calls (log to console).
*   **IF** git repo is missing **THEN** note it in the summary.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `session-end` | `git-state` | `work-summary`
*   **Outputs:** `engram-summary` | `session-closed`
