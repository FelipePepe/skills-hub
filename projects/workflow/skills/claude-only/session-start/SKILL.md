---
name: session-start
description: >
  Activates the session workflow: detects the active project, checks git state,
  reads the last journal and state docs, detects the active spec with pending
  tasks, queries context in Engram and Atlas (Atlas-first), checks codebase
  graph freshness via codebase-memory-mcp, and optionally runs quick
  tests/benchmarks. Returns a resumption briefing — or an onboarding briefing
  on first contact with a project — with next-step suggestions. Trigger: user
  says "start session", "session start", "resuming", "where did we leave off",
  "project state", "bring me up to speed", "session start".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.5"
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

### Step 5 — Persistent Memory (Atlas-first)

Fetch in parallel, but treat **Atlas as the primary source of truth** — it's where `session-end` now saves by default:

- Direct read of the **Atlas (Obsidian)** vault at `/mnt/nas/Obsidian/`:
  - `Projects/<name>.md` — project entity page, if it exists (architectural state).
  - If the `atlas_search` MCP is available, also use it. If not, use `grep`/`find` in the vault.
- `mem_context(project=<name>, limit=20)` — recent observations in Engram, for temporal/tactical detail Atlas doesn't carry (bugfixes, spec snapshots, in-progress state).

If Atlas and Engram disagree on the same fact, **Atlas wins** — it's the later, more deliberate write. Use Engram to fill gaps (what happened recently) rather than to override Atlas's architectural state.

Cross-check dates:
- If `Projects/<name>.md` has `Last updated:` earlier than the project's last journal → flag Atlas drift in the briefing (reconciliation is `session-end` work).
- If the last Engram observation is older than the last journal → flag "Engram outdated, N days of drift" (lower priority than Atlas drift).

### Step 6 — Codebase Graph (codebase-memory-mcp)

Run in parallel with Step 5 when the `codebase-memory` MCP tools are available in this session.

- `list_projects` — check whether the current repo is indexed.
- If indexed: `index_status` — compare the indexed commit against the HEAD commit from Step 2.
  - Index behind HEAD → flag "Codebase graph stale, N commits behind" in the briefing. Do **not** re-index automatically (that is `session-end` work, and can take minutes on large repos).
- If NOT indexed → note "Codebase graph not indexed for this project" in the briefing. Do not offer to index unless the user's request in this turn is explicitly structural.
- If the user's opening request is structural ("what changed", "who calls X", "show me the architecture") → use `get_architecture`, `search_graph`, or `detect_changes` to enrich the briefing instead of grep/Explore.

CAUTION: if the `codebase-memory` MCP is not connected this session, skip this step silently — do not block the briefing on it.

### Step 7 — Tests/Benchmark (optional, ask first)

Do NOT run automatically. Ask the user:

> "Shall I run tests + benchmark as a sanity check? (may take ~30s-2min)"

If they say yes:
- Detect the test command from the project's `CLAUDE.md` or conventions (`pytest`, `pnpm test`, `go test ./...`, `cargo test`, `unittest discover -s tests`)
- Respect venvs and paths documented in `CLAUDE.md` (e.g. vi-sdd uses `/home/sandman/.venvs/vi-sdd/bin/python`)
- Report green/red + number of tests; if red, do NOT attempt to fix — only flag it

### Step 8 — Briefing to User

Return a structured summary:

```
## Resumption point — <project>

**Branch:** <branch> · **Last commit:** <hash> <msg>
**Uncommitted changes:** <N files> | <none>
**Last session:** <journal date> — <title or first line>
**Codebase graph:** indexed as of <commit/date> | stale (N behind) | not indexed | unavailable

### Project state
- <bullet with key metrics from STATE/IMPLEMENTATION_SUMMARY>
- <bullet with active spec if any>

### Prioritized debt (top 3)
- <from STATE.md §debt or IMPLEMENTATION_SUMMARY>

### Suggested next step
<1-2 concrete sentences based on the last journal and pending tasks>
```

**Onboarding variant — first contact.** When the first-contact heuristic fires (see
Heuristics), the resumption template above makes no sense ("last session: none").
Replace it with an onboarding briefing that teaches the project instead:

```
## First contact — <project>

### What it is
<README/CLAUDE.md: purpose in 2-3 lines>

### Stack & conventions
<manifests: language, framework, package manager, test runner>
<CLAUDE.md rules that constrain how work is done here>

### Structure
<directory tree / README description: layers and where symbols concentrate>

### Entry points & hotspots
<main/server/app + top fan-in symbols — where to start reading>

### How to run / test
<build, test, dev commands — from CLAUDE.md or package scripts>

### Health signals
<tests present?, CI?, uncommitted work?>
```

If conflicts are detected (outdated engram, checkboxes vs IMPLEMENTATION_SUMMARY, red tests), add an **⚠ Attention** section with the detail.

After the briefing, always end with a **session intake** — ask these questions to collect everything needed before starting work. Present them as a compact block, not a wall of text:

```
### Before we start — a few questions:

1. **Goal** — What do you want to accomplish today?
2. **Constraints** — Any deadline, scope limit, or thing to avoid?
3. **Approach** — Should I propose a plan first, or dive straight in?
   - Need SDD cycle? (spec, tasks, phases)
   - Architecture decision that warrants DDIA tradeoff analysis?
   - Something else I should load before starting?
4. **Blockers** — Anything waiting on a PR, external dependency, or another person?
```

**Onboarding intake**: on first contact, prepend one extra question — "Is this your
first time in this repo, or are you resuming work started elsewhere (no memory
recorded on this machine)?" Engram-first-contact is not always user-first-contact;
if they are resuming, keep the onboarding structure but skip the teaching tone.

STOP after showing the intake. Do not assume answers, propose code, or begin any task until the user replies. Questions 2–4 are optional — if the user only answers question 1, that is enough to proceed.

---

## Operational Rules

- **Write nothing to disk** during session-start. Read only.
- **Do not modify memories** (engram/atlas) in start — that is `session-end` work.
- **Parallelize reads** whenever possible. Bash + Read + mem_context + atlas_search can go in the same turn.
- **Fail gracefully**: if engram, atlas, codebase-memory-mcp, or any file does not respond/exist → omit that section from the briefing, do not break the flow.
- **Respect project language**: if CLAUDE.md specifies Spanish (like vi-sdd, homelab), the briefing goes in Spanish. English by default.
- **Do not suggest code changes** in the briefing. The next-step suggestion is "which task to tackle", not "which line to edit".

---

## Heuristics

**Is this first contact? (onboarding mode)**
- ALL of these → first contact: mem_context has no observations for the project,
  no journal/STATE/IMPLEMENTATION_SUMMARY, no Atlas entity page. Use the onboarding
  briefing variant (Step 8) and prepend the first-time intake question.
- Only SOME signals missing (e.g. journal exists but Engram is empty) → resumption
  briefing; flag the missing store as drift instead of switching template.

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

**Is the codebase graph stale?**
- `index_status` commit older than the HEAD commit from Step 2 → stale, report the gap in commits.
- Not indexed at all is normal for a first session on a project — do not treat it as an error, just report it.
- Never call `index_repository` during session-start — indexing is a write/compute action reserved for `session-end` (with confirmation) or an explicit user request.

---

## Example Output (vi-sdd, simulated)

```
## Resumption point — vi-sdd

**Branch:** main · **Last commit:** abc1234 chore: close spec 006
**Uncommitted changes:** 12 untracked files (.artifacts/, .claude/, CLAUDE.md, docs/, specs/, src/, tests/)
**Last session:** 2026-05-21 — Closed spec 006 (OWASP coverage). Macro F1 0.998, 317 tests.
**Codebase graph:** stale (3 commits behind HEAD)

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

### Before we start — a few questions:

1. **Goal** — What do you want to accomplish today?
2. **Constraints** — Any deadline, scope limit, or thing to avoid?
3. **Approach** — Should I propose a plan first, or dive straight in?
   - Need SDD cycle? (spec, tasks, phases)
   - Architecture decision that warrants DDIA tradeoff analysis?
   - Something else I should load before starting?
4. **Blockers** — Anything waiting on a PR, external dependency, or another person?
```
