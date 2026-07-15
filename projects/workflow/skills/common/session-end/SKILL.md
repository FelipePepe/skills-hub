---
name: session-end
description: >
  Session cleanup and memory consolidation protocol. Runs at the end of every task
  to summarize work, persist findings (Atlas-first, Engram for temporal detail),
  check codebase graph freshness, and close the session cleanly.
  Trigger: Always active — execute when a task or request is fully completed.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
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

### Step 2b — Atlas update (if load-bearing, Atlas-first)

Atlas-first default: if the session included an architecture/stack decision or anything
still true in 6 months, prefer Atlas over Engram. Edit
`/mnt/nas/Obsidian/Projects/{current-project}.md` with the delta (refresh
`**Last updated:**`). This is usually an upsert on the existing page, not a new one.
If nothing load-bearing happened, skip — the Step 2 engram summary already covers it.

### Step 2c — Codebase graph freshness (codebase-memory-mcp)

**Only if** the `codebase-memory` MCP tools are available AND source files changed this session.
- `list_projects` — skip entirely if this repo was never indexed.
- If indexed: `index_status` vs current HEAD. If behind, ask the user before running
  `index_repository` — never re-index without confirmation.

### Step 3 — Close the session
```
engram-mem_session_end
```

This marks the session as completed and releases any tracked resources.

## Critical Rules

- Always include `🔲` items for work carried over to the next session
- Even if there is nothing to summarize, still run Steps 1 and 3
- Never run `index_repository` (Step 2c) without explicit user confirmation

## Output contract

After Step 3 emit exactly one line to the user:
```
SESSION:closed BRANCH:{name} COMMITTED:{yes|no} ATLAS:{updated|skip} GRAPH:{reindexed|stale-pending|skip}
```
No summary of what was done, no bullets, no headers. One line only.

## Relationship to session-start

- `session-start` reads engram context and verifies state before work begins
- `session-end` persists results and closes the session after work finishes
- Together they form a complete session lifecycle: init → work → persist → close
