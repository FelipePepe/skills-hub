---
name: session-start
description: >
  Activates the session workflow: detects the active project, checks git state,
  reads the last journal and state docs, detects the active spec with pending tasks,
  queries context in Engram and Atlas, and optionally runs quick tests/benchmarks.
  Returns a resumption briefing with next-step suggestions. Trigger: user says
  "start session", "session start", "resuming", "where did we leave off",
  "project state", "bring me up to speed", "session start".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## When to Use This Skill

- The user opens a new session on a project and wants to resume context
- The user says "where did we leave off", "bring me up to speed", "project state"
- After several days away from a project, when returning to it
- Before starting to code in a non-trivial repo

Do NOT use if:
- The user asks something specific that does NOT require reloading project context
- session-start has already been run in this same session

---

## Startup Protocol

Execute steps in this order. **Parallelize** independent calls in the same turn (git + reads + mem_context + atlas_search are all independent).

### Step 1 — Detect the Active Project

- `pwd` and look for project markers: `.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`
- If there is a `CLAUDE.md` in the directory: read it (policies, conventions, venv, commands)
- If there is a `CLAUDE.md` in `~/.claude/`: already loaded automatically — do not re-read
- Canonical project name = directory name or `package.json::name`/`pyproject.toml::project.name`

### Step 2 — Git State

Run in parallel in a single turn:

- `git status --short` (uncommitted changes)
- `git branch --show-current` + `git log --oneline -5` (branch + last 5 commits)
- `git stash list` (pending stashes)

If there are uncommitted changes or stashes → flag them in the briefing.

### Step 3 — State Documentation

Read if they exist (in order, without failing if any is missing):

1. `docs/journal/sessions/` — most recent entry by date
2. `docs/STATE.md` — executive snapshot
3. `IMPLEMENTATION_SUMMARY.md` — capabilities and spec state
4. `README.md` — only if the above do not exist

### Step 4 — Active Spec (if the project follows SDD)

- Look for `specs/NNN-*/tasks.md` (descending numeric order — the last is usually the active one)
- For each spec, count `- [ ]` checkboxes (pending) vs `- [x]` (closed)
- Active spec = the last one whose pending ratio > 0 AND whose last edit is recent

CAUTION: unchecked checkboxes may be stale. Cross-reference with `IMPLEMENTATION_SUMMARY.md` or the journal before stating "spec X has Y pending tasks". If the summary says "closed" and checkboxes are unchecked → report the conflict, do not assume it is open.

### Step 5 — Persistent Memory

Run in parallel:

- `mem_context(project=<name>, limit=20)` — recent observations in Engram.
- Direct read of the **Atlas (Obsidian)** vault at `/mnt/nas/Obsidian/`:
  - `Projects/<name>.md` — project entity page, if it exists (architectural state).
  - If the `atlas_search` MCP is available, also use it. If not, use `grep`/`find` in the vault.

Cross-check dates:
- If the last Engram observation is older than the last journal → flag "Engram outdated, N days of drift".
- If `Projects/<name>.md` has `Last updated:` earlier than the project's last journal → flag Atlas drift in the briefing (reconciliation is `session-end` work).

### Step 6 — Tests/Benchmark (optional, ask first)

Do NOT run automatically. Ask the user:

> "Shall I run tests + benchmark as a sanity check? (may take ~30s-2min)"

If they say yes:
- Detect the test command from the project's `CLAUDE.md` or conventions (`pytest`, `pnpm test`, `go test ./...`, `cargo test`, `unittest discover -s tests`)
- Respect venvs and paths documented in `CLAUDE.md` (e.g. vi-sdd uses `/home/sandman/.venvs/vi-sdd/bin/python`)
- Report green/red + number of tests; if red, do NOT attempt to fix — only flag it

### Step 7 — Briefing to User

Return a structured summary:

```
## Resumption point — <project>

**Branch:** <branch> · **Last commit:** <hash> <msg>
**Uncommitted changes:** <N files> | <none>
**Last session:** <journal date> — <title or first line>

### Project state
- <bullet with key metrics from STATE/IMPLEMENTATION_SUMMARY>
- <bullet with active spec if any>

### Prioritized debt (top 3)
- <from STATE.md §debt or IMPLEMENTATION_SUMMARY>

### Suggested next step
<1-2 concrete sentences based on the last journal and pending tasks>
```

If conflicts are detected (outdated engram, checkboxes vs IMPLEMENTATION_SUMMARY, red tests), add an **⚠ Attention** section with the detail.

---

## Operational Rules

- **Write nothing to disk** during session-start. Read only.
- **Do not modify memories** (engram/atlas) in start — that is `session-end` work.
- **Parallelize reads** whenever possible. Bash + Read + mem_context + atlas_search can go in the same turn.
- **Fail gracefully**: if engram, atlas, or any file does not respond/exist → omit that section from the briefing, do not break the flow.
- **Respect project language**: if CLAUDE.md specifies Spanish (like vi-sdd, homelab), the briefing goes in Spanish. English by default.
- **Do not suggest code changes** in the briefing. The next-step suggestion is "which task to tackle", not "which line to edit".

---

## Heuristics

**Is there an active spec?**
- `specs/NNN-*/tasks.md` exists with `- [ ]` pending AND the journal/STATE does not explicitly say "closed" → yes
- If `IMPLEMENTATION_SUMMARY.md` says "closed on <date>" and checkboxes are unchecked → stale checkboxes, NO active spec

**Is Engram outdated?**
- Last observation with `project=<X>` > 7 days before the last journal → outdated
- Suggest at the end of the briefing: "Consider running `/session-end` at the end of today to sync Engram"

**Is Atlas relevant?**
- The Atlas vault lives in `/mnt/nas/Obsidian/`. Structure: `Projects/<project>.md` (entity page), `Stack/<category>/<tech>.md` (tech catalog with `_INDEX.md`), `Setup/` (infra), `AI/`, `Temp/`.
- If `Projects/<project>.md` exists → always read it: it has stable architectural state + backlinks to relevant Stack technologies.
- For small personal projects without an entity page, skip.

---

## Example Output (vi-sdd, simulated)

```
## Resumption point — vi-sdd

**Branch:** main · **Last commit:** abc1234 chore: close spec 006
**Uncommitted changes:** 12 untracked files (.artifacts/, .claude/, CLAUDE.md, docs/, specs/, src/, tests/)
**Last session:** 2026-05-21 — Closed spec 006 (OWASP coverage). Macro F1 0.998, 317 tests.

### Project state
- 6 specs closed (001→006). 6-stage pipeline: prepare→scan→validate→dedup→prove→report.
- Macro F1 0.998, 0 FPs, 7 OWASP categories covered. Latest metric is a record.
- No active spec with pending phases.

### Prioritized debt (top 3)
- Calibrate LLM auditor (qwen2.5-coder:7b hallucinates; F1 with auditor drops to 0.76)
- Real CVE OSS fixtures (Heartbleed, getaddrinfo) — spec 004 phase 10.1
- A01 Django/Spring handler collectors (framework detected, handlers not collected)

### Suggested next step
If you want to continue: open spec 007 extending A07/A10 to Java/C#/Go/Rust, or an iterative auditor calibration session (1-2h). If the goal is to consolidate: commit current state (there are docs/, specs/, src/ untracked).

⚠ Engram was outdated as of 2026-05-18 — synced in the previous session. OK.
```
