---
name: session-end
description: >
  Structured session close: reviews work done, separates operational (Engram)
  from stable architectural (Atlas) knowledge, searches for duplicates before
  saving, persists each observation in canonical format, and optionally adds
  an entry to the project journal. Trigger: user says "close the session",
  "end of session", "save to engram", "save context", "summarize what we did",
  "what do we save from this session".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.1"
---

## When to Use

- User explicitly requests closing/saving at the end of a session
- Significant work was done (deploy, feature, bugfix, architectural decision)
- User says "wrapping up", "save the important stuff", "summarize the session"
- Decisions/learnings are detected that are not in persistent memory

Do NOT use if:
- The session was trivial (a typo, a question with no code)
- session-end has already run in this turn

---

## Close Protocol

### Step 1 — Review session history

Go through the conversation and identify candidates. For each one, decide type:

| Type | Save if... |
|------|-----------|
| `decision` | Architecture/technology/approach decision that is not obvious |
| `bugfix` | Resolved error — symptom, root cause, fix |
| `architecture` | Structure designed/documented (module, network, system) |
| `pattern` | Repeatable convention or way of working |
| `config` | Environment configuration (nginx, systemd, DNS, env vars) |
| `discovery` | Undocumented finding (occupied port, limitation, unexpected behavior) |

**Do not save**:
- Obvious steps or officially documented procedures
- Code already in the repo (repo is source of truth)
- Temporary state (in-progress tasks, TODOs without context)
- Things already in Engram/Atlas — verify first

### Step 2 — Classify destination: Engram vs Atlas

Each candidate goes to ONE destination (not both unless explicitly justified).

**Atlas — persistent architectural knowledge** (life span >6 months, cross-session):
- Lives in `/mnt/nas/Obsidian/` (Obsidian vault). Primary access via filesystem (Read/Write/Edit).
- Structure: `Projects/<project>.md` (entity page per project), `Stack/<category>/<tech>.md` (tech reference), `Setup/` (infra/operational), `AI/`, `Temp/`.
- "Load-bearing" architecture decisions: stack choice, data model, stable API contracts.
- Organizational conventions that apply to multiple projects.
- Canonical mappings and established team/personal work patterns.
- **Most typical at session close**: if a spec/phase was closed with architectural substance, **update `Projects/<project>.md`** with the delta (current state, metrics, new Stack links). Convention: refresh `**Last updated:** YYYY-MM-DD` at the top.

**Engram — operational memory** (life span weeks-months, day-to-day):
- Resolved bugs (symptom+cause+fix)
- Spec state and metrics (temporal snapshots)
- Concrete environment configuration (venv, ports, paths)
- Prioritized technical debt
- Tactical decisions within a spec

**Quick rule**: if the answer to "will this still be true in 6 months?" is YES → atlas. If "it depends on the current state" → engram.

### Step 3 — Search for duplicates before saving

For each candidate:

- Engram: `mem_search("<title or keywords>", project=<X>)`. If similar exists: use `topic_key` for upsert with `mem_save` or `mem_update`.
- Atlas: check if `Projects/<project>.md` exists in `/mnt/nas/Obsidian/`. If yes → edit the relevant section (do not create a new page). If the observation spans multiple projects or is about a technology, consider `Stack/<category>/<tech>.md`. Last resort: create a new page — only if the topic truly does not fit any existing one.

`topic_key` values (Engram) must be stable and composite: `vi-sdd/spec-006-owasp`, `homelab/nginx-config`, `personal/git-workflow`.

### Step 4 — Save with canonical format

Required format for `content` (engram and atlas):

```
**What**: [what was done or decided, in one line]
**Why**: [why it matters, what problem it solves]
**Where**: [paths, files, commands, affected services]
**Learned**: [gotchas, edge cases, decisions made — omit if not applicable]
```

**Titles**: short, searchable, prefixed by project when applicable.
- ✅ `vi-sdd: dedup command-injection-sink (spec 006 phase 8)`
- ✅ `homelab: nginx on pihole2 - reload without restart`
- ❌ `fixed a problem with nginx`

Run saves in parallel when independent (multiple `mem_save` in a single turn).

### Step 5 — Project journal (if applicable)

If the project has `docs/journal/sessions/` and the session was substantial:

- Check if an entry for today already exists: `docs/journal/sessions/YYYY-MM-DD.md`
- If it does NOT exist and the session justifies an entry: **ask the user** before creating it
- If it already exists: ask whether to append the advances from this turn
- Do NOT create journal automatically — always confirm

If the project has no `docs/journal/` → skip this step.

### Step 6 — Report

Emit exactly this schema:

```
SAVED:{n items} SKIPPED:{n — reason}
ENGRAM:{title:type:save|update} ...
ATLAS:{page:section:edit|create} ...
JOURNAL:{path|none}
```
One ENGRAM line per saved item. One ATLAS line per saved item. No prose.

---

## Operating Rules

- **Do not invent** observations — only save what happened in the conversation.
- **Do not duplicate** — always `mem_search`/`atlas_search` first. Upsert with `topic_key`.
- **Parallelism**: independent saves go in the same turn.
- **Atlas conservative**: when in doubt, use Engram. Only Atlas if the decision is clearly architectural and stable.
- **Do not silence errors**: if engram/atlas fails, report to the user what remains pending.
- **Always respond in English.**

## Output contract

Respond ONLY in the schema defined in Step 6. No preamble, no heuristic commentary, no prose outside the schema.
