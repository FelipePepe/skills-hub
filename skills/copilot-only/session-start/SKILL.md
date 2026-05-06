---
name: session-start
description: >
  Always-active session initialization protocol. Reads engram memory, verifies
  GitFlow branch state, and checks SDD context at the start of every session.
  Trigger: Always active — load in every session automatically.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.2"
---

## When to Use

ALWAYS ACTIVE — execute this at the very beginning of every session, before any other action.

## Protocol

At session start, run ALL steps in this exact order:

### Step 1 — Run session-start hook
```bash
bash ~/.copilot/hooks/copilot/session-start.sh
```
Use the output to call `engram-mem_session_start` with the project id and directory.

### Step 2 — Check GitFlow branch (MANDATORY before any code change)
```bash
bash ~/.copilot/hooks/copilot/gitflow-check.sh
```
- If exit code != 0: **STOP**. Create the correct feature branch before touching any file.
- If "No es un repositorio git": **initialize git first** (`git init`), then set up `main` + `develop` + `feature/<name>` before writing any code.
- If ✓ OK: proceed.

### Step 3 — Check SDD context (MANDATORY before implementing any feature)
Check if the project uses SDD by looking for an `openspec/` directory:
```bash
ls openspec/config.yaml 2>/dev/null && cat openspec/config.yaml || echo "No SDD config found"
```
- If `openspec/` exists: **SDD is active for this project.**
  - Check for an active change: `ls openspec/changes/` — if there's a change without `archived_at`, resume it with `sdd status`.
  - If there is NO active change and the user asks to implement a feature: **run `sdd new "<feature>"` BEFORE writing any code.**
  - Remind the user: *"Este proyecto usa SDD — ¿arranco con `sdd new` o hay un change activo?"*
- If no `openspec/`: SDD is not configured, skip this step.

### Step 4 — Read engram context
```
engram-mem_context project="{current-project}"
```
Infer the project name from the git repo name or working directory.

### Step 5 — Surface pending work
Look for:
- Observations tagged as `in_progress` or `blocked`
- Session summaries with `🔲` (unfinished) items
- Any explicit "TODO" or "next session" notes

### Step 6 — Report to user
Summarise briefly:
- Active git branch
- Active SDD change (if any) with its current phase
- Pending engram work (if any)
- Ask what to do next

## Critical Rules

- **Never skip any step**, even for "quick" requests
- **Step 2 (GitFlow check) must happen before the first file edit**, not after
- **Step 3 (SDD check) must happen before implementing ANY new feature or phase**
- If the project has no git repo, initializing git IS part of the workflow — do it before coding
- Do NOT start implementing a feature without an active SDD change unless the user explicitly overrides
- Do NOT block the user waiting — if engram has nothing relevant, move on immediately
- At session end: run `bash ~/.copilot/hooks/copilot/session-end.sh` and call `engram-mem_session_summary` + `engram-mem_session_end`

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
