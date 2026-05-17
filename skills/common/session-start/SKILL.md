---
name: session-start
description: >
  Session initialization protocol. Recovers memory context, verifies branch
  state, and checks SDD status at the start of every session.
  Trigger: Always active — execute at the beginning of every session before any other action.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  version: "2.0"
  harness: agnostic
---

## When to Use

ALWAYS ACTIVE — execute at the very beginning of every session, before any other action.

## Compact Protocol

### Step 1: Recover Memory
- Call `mem_context` → brief yourself on last session state

### Step 2: Check Branch
```bash
git status --short && git branch --show-current && git log --oneline -5
```
Warn on uncommitted changes on protected branches; verify naming convention.

### Step 3: Check SDD
Check `openspec/changes/` for active changes. If DB available, query `sdd_cycle` table.

### Step 4: Report Brief
```
## Session Start
**Branch**: {name} {⚠️ warning}
**Memory**: {recovered N / none}
### Active SDD Changes
{name} — phase: {phase} → {next action}
### Ready
{What to do now}
```

## Rules

- NEVER skip Step 1 — cold starts waste tokens and lose context
- NEVER proceed with uncommitted changes on a protected branch without warning
- NEVER assume which SDD phase is active without checking state
- If memory backend unavailable, say so explicitly
