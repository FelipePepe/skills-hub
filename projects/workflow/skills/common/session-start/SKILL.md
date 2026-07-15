---
name: session-start
description: >
  Always-active session initialization protocol. Reads engram memory, verifies
  GitFlow branch state, and checks SDD context at the start of every session.
  Trigger: Always active — load in every session automatically.
license: Apache-2.0
metadata:
  author: Felipe Pérez (Sandman_owl)
  version: "1.3"
---

## When to Use

ALWAYS ACTIVE — execute this at the very beginning of every session, before any other action.

## Protocol

At session start, run ALL steps in this exact order:

### Step 1 — Collect session context
```bash
git rev-parse --show-toplevel 2>/dev/null && git branch --show-current && git log --oneline -5 && git status --short
```
- `PROJECT` = basename of the repo root (or `pwd` if no git)
- `BRANCH` = current branch (or `no-git` if no repository)
- Call `engram-mem_session_start` with `id="{PROJECT}-{YYYYMMDD-HHMM}"` and `directory="{pwd}"`.

### Step 2 — Check GitFlow branch (MANDATORY before any code change)
```bash
git branch --show-current 2>/dev/null || echo "no-git"
```
- If no git repo: **initialize git first** (`git init`), then create `main` + `develop` + `feature/<name>` before writing any code.
- If branch is `main`, `master`, or `develop`: **STOP**. Create a working branch first:
  ```bash
  git checkout develop && git checkout -b feature/<descriptive-name>
  ```
- If branch does not match `^(feature|fix|hotfix|chore|release|docs|test|refactor)/`: **STOP**. Rename or create a compliant branch. Valid types: `feature | fix | hotfix | chore | release | docs | test | refactor`.
- If ✓ OK: proceed.

### Step 3 — Check SDD context (MANDATORY before implementing any feature)
Check if the project uses SDD by looking for an `openspec/` directory:
```bash
ls openspec/config.yaml 2>/dev/null && cat openspec/config.yaml || echo "No SDD config found"
```
- If `openspec/` exists: **SDD is active for this project.**
  - Check for an active change: `ls openspec/changes/` — if there's a change without `archived_at`, resume it with `sdd status`.
  - If there is NO active change and the user asks to implement a feature: **run `sdd new "<feature>"` BEFORE writing any code.**
  - Remind the user: *"This project uses SDD — should I start with `sdd new` or is there an active change?"*
- If no `openspec/`: SDD is not configured, skip this step.

### Step 4 — Read engram context
**Only run if** Step 1 returned a valid project id OR Step 3 found an active change. Otherwise skip.
```
engram-mem_context project="{current-project}"
```


### Step 5 — Report to user
Emit exactly this schema, then ask what to do next in one sentence:
```
BRANCH:{name} SDD:{change@phase|none} PENDING:{item|none}
```
No headers, no bullets, no explanation. Omit PENDING if none.

## Critical Rules

- **Never skip any step**, even for quick requests
- Step 2 is the gate — no file edit before GitFlow check passes
- Engram unavailability is not a blocker — skip Step 4 gracefully and continue

## Output contract

Respond ONLY in the schema defined in Step 5. No preamble, no markdown headers,
no explanation of what you did. One schema line + one question sentence. Nothing else.
