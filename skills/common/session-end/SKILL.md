---
name: session-end
description: >
  Session cleanup and memory consolidation protocol. Runs at the end of every task
  to summarize work, persist findings, and close the session cleanly.
  Trigger: Always active — execute when a task or request is fully completed.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

ALWAYS ACTIVE — execute this at the end of every completed task or request, before closing the session.

## Protocol

At session end, run ALL steps in this exact order:

### Step 1 — Gather git context
```bash
bash ~/.copilot/hooks/copilot/session-end.sh
```

This hook outputs structured session context:
- Current branch
- Date/time
- Changed files (staged + unstaged)
- Last 5 commits
- Uncommitted changes

### Step 2 — Call engram session summary
Use the hook output to call `engram-mem_session_summary` with the following format:

```
## Goal
[One sentence: what was being worked on]

## Instructions
[User preferences, constraints, or context discovered during the session]

## Discoveries
- [Technical finding, gotcha, or learning]

## Accomplished
- ✅ [Completed task — with key implementation details]
- 🔲 [Identified but not yet done — for next session]

## Relevant Files
- path/to/file.md — [role in the work]
```

### Step 3 — Close the session
```
engram-mem_session_end
```

This marks the session as completed and releases any tracked resources.

## Critical Rules

- **Never skip Step 1** — the hook output provides essential git context for the summary
- **Never skip Step 2** — the summary is what preserves work across sessions
- **Never skip Step 3** — the session must be closed cleanly
- Always include the `🔲` items for work carried over to the next session
- If the project has no git repo, note it explicitly in the summary
- Do not block the user — if there is no work to summarize, still close the session

## Output contract

After Step 3 emit exactly one line to the user:
```
SESSION:closed BRANCH:{name} COMMITTED:{yes|no}
```
No summary of what was done, no bullets, no headers. One line only.

## Relationship to session-start

- `session-start` reads engram context and verifies state before work begins
- `session-end` persists results and closes the session after work finishes
- Together they form a complete session lifecycle: init → work → persist → close
