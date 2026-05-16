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

Harness adapters can automate this via lifecycle hooks (`before_agent_start`, `SessionStart`, etc.). If no hook is configured, the agent runs this protocol manually on first message.

## Protocol

Run ALL steps in this order:

---

### Step 1 — Recover Memory Context

Invoke the **memory harness** (`memory` skill) session-start protocol:

```
1. Call mem_context (or equivalent) — recovers most recent session summary
2. If topic is referenced by the user: call mem_search with relevant keywords
3. If found: retrieve full content (previews are truncated, always get full)
4. Brief yourself on: what was last done, decisions made, what's next
```

If no memory backend is available: proceed without context (note this to the user).

---

### Step 2 — Check Branch State

```bash
git status --short
git branch --show-current
git log --oneline -5
```

Evaluate:
- Are there uncommitted changes? (warn the user)
- Is the branch following the project's branch naming convention?
  - `feature/*` for new work
  - `fix/*` or `hotfix/*` for bug fixes
  - `release/*` for release preparation
  - `main` / `develop` — warn if working directly on protected branches
- Is the branch up-to-date with its base? (`git fetch --dry-run`)

Report any anomalies clearly.

---

### Step 3 — Check SDD State

Query the active SDD cycle:

```sql
SELECT feature, phase, artifact_mode, verify_pass,
       datetime(updated_at/1000, 'unixepoch') as updated
FROM sdd_cycle
WHERE phase != 'done'
ORDER BY updated_at DESC
LIMIT 3;
```

If no DB access: check `openspec/changes/` for active (non-archived) changes.

Report:
- Active changes and their current phase
- Any blocked gates
- What the next recommended action is

If no active SDD cycle: report "No active SDD cycle. Ready to start a new one."

---

### Step 4 — Report Session Start Summary

Output a concise brief:

```
## Session Start

**Branch**: {branch-name} {⚠️ warning if anomaly}
**Memory**: {recovered N decisions / no context available}

### Active SDD Changes
{change-name} — phase: {phase} → next: {next action}
{or: No active changes}

### Last Session Summary
{1-2 sentences from memory context, or "No prior session found"}

### Ready
{What to do now — continue previous work, or start fresh}
```

---

## Harness-Specific Automation

| Harness | How to automate this protocol |
|---|---|
| **Pi** | Extension `session-guard.ts` hooks `before_agent_start` → runs steps 1-4 and injects summary into system prompt |
| **Claude Code** | `SessionStart` hook in `settings.json` → shell script that runs steps 2-3 and saves to a temp file that Claude reads |
| **OpenCode** | `SessionStart` lifecycle event → agent invokes `/session-start` slash command automatically |
| **Any** | Run `/session-start` manually as first message |

## Rules

- NEVER skip Step 1 — cold starts waste tokens and lose context
- NEVER proceed with uncommitted changes on a protected branch without warning
- NEVER assume which SDD phase is active without querying state
- If memory backend is unavailable, say so explicitly — do not pretend context was recovered
