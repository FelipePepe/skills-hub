---
name: session-start
description: >
  Activates the session workflow: detects the active project, checks git state,
  reads the last journal and status docs, detects active spec with pending tasks,
  queries context in Engram and Atlas, and optionally runs quick tests/benchmarks.
  Returns a resumption briefing with next-step suggestions. Trigger: user says
  "let's start a session", "session start", "where did we leave off",
  "what's the project status", "catch me up", "session init".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.1"
---

## When to Use

- User opens a new session on a project and wants to resume context
- User says "where did we leave off", "catch me up", "project status"
- Returning to a project after several days away
- Before starting to code in a non-trivial repo

Do NOT use if:
- The user asks something specific that does NOT require reloading project context
- session-start has already run in this session

---

## Startup Protocol

Run steps in this order. **Parallelize** independent calls in a single turn (git + reads + mem_context + atlas_search are all independent).

### Step 1 — Detect active project

- `pwd` and look for project markers: `.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`
- If `CLAUDE.md` exists in the directory: read it (policies, conventions, venv, commands)
- If `CLAUDE.md` is in `~/.claude/`: already loaded automatically — do not re-read
- Canonical project name = directory name or `package.json::name` / `pyproject.toml::project.name`

### Step 2 — Git state

Run in parallel in a single turn:

- `git status --short` (uncommitted changes)
- `git branch --show-current` + `git log --oneline -5` (branch + last 5 commits)
- `git stash list` (pending stashes)

If there are uncommitted changes or stashes → flag them in the briefing.

### Step 3 — Status documentation

Read if they exist (in order, without failing if any is missing):

1. `docs/journal/sessions/` — latest entry by date
2. `docs/STATE.md` — executive snapshot
3. `IMPLEMENTATION_SUMMARY.md` — capabilities and spec status
4. `README.md` — only if the above do not exist

### Step 4 — Active spec (if the project uses SDD)

- Look for `specs/NNN-*/tasks.md` (descending numerical order — the last is usually active)
- For each spec, count `- [ ]` (pending) vs `- [x]` (closed) checkboxes
- Active spec = the last one with pending ratio > 0 AND whose last edit is recent

CAUTION: unchecked checkboxes can be stale. Cross-reference with `IMPLEMENTATION_SUMMARY.md` or the journal before asserting "spec X has Y pending". If the summary says "closed" and checkboxes are unchecked → report the conflict, do not assume it is open.

### Step 5 — Persistent memory

Run in parallel:

- `mem_context(project=<name>, limit=20)` — recent observations in Engram.
- Direct read of the **Atlas (Obsidian)** vault at `/mnt/nas/Obsidian/`:
  - `Projects/<name>.md` — project entity page, if it exists (architectural state).
  - If MCP `atlas_search` is available, use it additionally. If not, `grep`/`find` in the vault.

Cross-check dates:
- If the last Engram observation is older than the last journal → flag "Engram out of date, N days of drift".
- If `Projects/<name>.md` has `Last updated:` before the project's last journal → flag Atlas drift in the briefing (reconciliation is session-end's job).

### Step 6 — Quick tests/benchmark (optional, ask first)

Do NOT run automatically. Ask the user:

> "Run tests + benchmark as a sanity check? (may take ~30s-2min)"

If yes:
- Detect test command from project `CLAUDE.md` or conventions (`pytest`, `npm test`, `go test ./...`, `cargo test`, `unittest discover -s tests`)
- Respect venvs and paths documented in `CLAUDE.md`
- Report green/red + test count; if red, do NOT attempt to fix — only flag

### Step 7 — Briefing

Emit exactly this schema:

```
BRANCH:{name} COMMIT:{hash message} UNCOMMITTED:{n files|none}
LAST_SESSION:{date — title or first line|none}
STATUS:{1-2 bullet points from STATE/IMPLEMENTATION_SUMMARY}
ACTIVE_SPEC:{spec-name: N pending|none}
DEBT:{item1;item2;item3|none}
ENGRAM:{ok|out-of-date:N days}
NEXT:{1-2 concrete sentences on what task to tackle}
```

If conflicts found (stale Engram, checkbox vs IMPLEMENTATION_SUMMARY mismatch, red tests), append:
`ATTENTION:{description of conflict}`

---

## Operating Rules

- **Write nothing to disk** during session-start. Read-only.
- **Do not modify memories** (engram/atlas) on start — that is session-end's job.
- **Parallelize reads** whenever possible. Bash + Read + mem_context + atlas_search can go in the same turn.
- **Fail gracefully**: if engram, atlas, or any file does not respond/exist → omit that section from the briefing, do not break the flow.
- **Do not suggest code changes** in the briefing. The next-step suggestion is "which task to tackle", not "which line to edit".
- **Always respond in English.**

## Output contract

Respond ONLY in the schema defined in Step 7. No preamble, no prose outside the schema.
