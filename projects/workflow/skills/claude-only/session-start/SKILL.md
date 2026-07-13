---
name: session-start
description: >
  Activates the session workflow: detects the active project, ensures a CodeGraph
  index and pulls a structural overview, checks git state, reads the last journal
  and state docs, detects the active spec with pending tasks, queries context in
  Engram and Atlas, and optionally runs quick tests/benchmarks. Returns a
  resumption briefing — or an onboarding briefing on first contact with a
  project — with next-step suggestions. Trigger: user says
  "start session", "session start", "resuming", "where did we leave off",
  "project state", "bring me up to speed", "session start".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.4"
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

Execute steps in this order. **Parallelize** independent calls in the same turn (git + reads + mem_context + atlas_search are all independent). CodeGraph `init`/`sync` must complete before `status`/`files` — those queries read the index the first two write.

### Step 1 — Detect the Active Project

- `pwd` and look for project markers: `.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`
- If there is a `CLAUDE.md` in the directory: read it (policies, conventions, venv, commands)
- If there is a `CLAUDE.md` in `~/.claude/`: already loaded automatically — do not re-read
- Canonical project name = directory name or `package.json::name`/`pyproject.toml::project.name`

### Step 2 — CodeGraph Structural Context

Resolve the project root (`git rev-parse --show-toplevel || pwd`), then:

1. Check for `<project-root>/.codegraph/`.
2. If missing AND the root is a real project (has `.git` or a package manifest): run
   `codegraph init <project-root>` once. Never init in `$HOME`, temp directories, or
   non-project folders. This is the ONLY write session-start is allowed to perform.
   - **Silence the spinner**: the init progress bar floods the transcript with ANSI
     frames. Redirect and show only the summary:
     `codegraph init <root> > /tmp/cg-init.log 2>&1; tail -3 /tmp/cg-init.log`
     (use `--quiet` instead if the CLI version supports it).
   - **After a fresh init**: `codegraph init` drops a self-ignoring
     `.codegraph/.gitignore` (`*` + `!.gitignore`) — the data files never reach git,
     but that one file is MEANT to be committed so the ignore travels with the repo.
     If `git status` shows `?? .codegraph/`, suggest committing
     `.codegraph/.gitignore` in the briefing — do NOT commit or edit anything
     yourself (read-only rule).
3. If the index already exists, run
   `codegraph sync <root> > /tmp/cg-sync.log 2>&1; tail -3 /tmp/cg-sync.log` —
   it ingests changes since the last index (a no-op when nothing changed), so the
   structure below always reflects the CURRENT working tree. No mtime staleness
   heuristics: comparing against the last commit misses uncommitted edits.
4. Query the index for the briefing with deterministic, summary-level commands:
   - `codegraph status` — files/nodes/edges counts + node-kind distribution
   - `codegraph files` — annotated project tree (symbols per file): the layers line
   - Do NOT use `codegraph explore` here: it is semantic search for editing tasks —
     it matches a narrow symbol set and dumps verbatim source. Reserve it for when
     the session goal is refactoring and blast-radius matters up front (then trim
     with `| sed '/\*\*Source Code\*\*/q'`).
5. Feed the result into the briefing's **Project state** section (structure line) — it
   replaces broad Read/Glob/Grep exploration, do not do both.

Fail gracefully: if `codegraph` is not installed, or init/sync/status fails, skip this
step, note "CodeGraph unavailable" in ⚠ Attention, and fall back to normal file reads.
On very large repos, init may take a while — mention it is running rather than stalling
silently.

### Step 3 — Git State

Run in parallel in a single turn:

- `git status --short` (uncommitted changes)
- `git branch --show-current` + `git log --oneline -5` (branch + last 5 commits)
- `git stash list` (pending stashes)

If there are uncommitted changes or stashes → flag them in the briefing.

### Step 4 — State Documentation

Read if they exist (in order, without failing if any is missing):

1. `docs/journal/sessions/` — most recent entry by date
2. `docs/STATE.md` — executive snapshot
3. `IMPLEMENTATION_SUMMARY.md` — capabilities and spec state
4. `README.md` — only if the above do not exist

### Step 5 — Active Spec (if the project follows SDD)

- Look for `specs/NNN-*/tasks.md` (descending numeric order — the last is usually the active one)
- For each spec, count `- [ ]` checkboxes (pending) vs `- [x]` (closed)
- Active spec = the last one whose pending ratio > 0 AND whose last edit is recent

CAUTION: unchecked checkboxes may be stale. Cross-reference with `IMPLEMENTATION_SUMMARY.md` or the journal before stating "spec X has Y pending tasks". If the summary says "closed" and checkboxes are unchecked → report the conflict, do not assume it is open.

### Step 6 — Persistent Memory

Run in parallel:

- `mem_context(project=<name>, limit=20)` — recent observations in Engram.
- Direct read of the **Atlas (Obsidian)** vault at `/mnt/nas/Obsidian/`:
  - `Projects/<name>.md` — project entity page, if it exists (architectural state).
  - If the `atlas_search` MCP is available, also use it. If not, use `grep`/`find` in the vault.
- **If `grafos_recall` is available**: call `grafos_recall("<project> session decisions files")` — returns graph entities and relations relevant to the current project. Add any returned context to the briefing. Grafos unavailability is not a blocker — skip gracefully.

Cross-check dates:
- If the last Engram observation is older than the last journal → flag "Engram outdated, N days of drift".
- If `Projects/<name>.md` has `Last updated:` earlier than the project's last journal → flag Atlas drift in the briefing (reconciliation is `session-end` work).

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

### Project state
- <bullet with structural overview from codegraph explore: modules/layers, entry points, hotspots>
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
<codegraph files tree: layers and where symbols concentrate>

### Entry points & hotspots
<main/server/app + top fan-in symbols — where to start reading>

### How to run / test
<build, test, dev commands — from CLAUDE.md or package scripts>

### Health signals
<tests present?, CI?, uncommitted work?, index stats from codegraph status>
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

- **Write nothing to disk** during session-start. Read only. Single exception: `codegraph init` / `codegraph sync` (Step 2) — they only write inside `.codegraph/`, never touch project sources.
- **Do not modify memories** (engram/atlas) in start — that is `session-end` work.
- **Parallelize reads** whenever possible. Bash + Read + mem_context + atlas_search can go in the same turn.
- **Fail gracefully**: if engram, atlas, or any file does not respond/exist → omit that section from the briefing, do not break the flow.
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

### Before we start — a few questions:

1. **Goal** — What do you want to accomplish today?
2. **Constraints** — Any deadline, scope limit, or thing to avoid?
3. **Approach** — Should I propose a plan first, or dive straight in?
   - Need SDD cycle? (spec, tasks, phases)
   - Architecture decision that warrants DDIA tradeoff analysis?
   - Something else I should load before starting?
4. **Blockers** — Anything waiting on a PR, external dependency, or another person?
```
