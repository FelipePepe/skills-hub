---
name: session-end
description: >
  Structured session close: reviews work done, separates operational memory (Engram)
  from stable architectural knowledge (Atlas), checks for duplicates before saving,
  persists each observation in canonical format, and optionally adds an entry to the
  project journal. Trigger: user says "close the session", "end of session", "save to
  engram", "save context", "summarize what we did", "what do we save from this session",
  or at the end of a long working session. Replaces the old `engram-fin-sesion`.
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## When to Use This Skill

- The user explicitly asks to close/save at the end of a session
- Significant work was done (deploy, feature, bugfix, architectural decision)
- The user says "let's wrap up", "save what matters", "summarize the session"
- Decisions/learnings are detected that are not in persistent memory

Do NOT use if:
- The session was trivial (a typo, a question without code)
- session-end was already run in this same turn

---

## Closing Protocol

### Step 1 — Review the Session History

Go through the conversation and identify candidates. For each one, decide the type:

| Type | Save if... |
|------|-----------|
| `decision` | Non-obvious architecture/technology/approach decision |
| `bugfix` | Resolved error — symptom, root cause, fix |
| `architecture` | Designed/documented structure (module, network, system) |
| `pattern` | Repeatable convention or way of working |
| `config` | Environment configuration (nginx, systemd, DNS, env vars) |
| `discovery` | Undocumented finding (occupied port, limitation, unexpected behavior) |

**Do NOT save**:
- Obvious steps or officially documented behavior
- Code already in the repo (the repo is the source of truth)
- Temporary state (in-progress tasks, TODOs without context)
- Things already in Engram/Atlas — verify first

### Step 2 — Classify Destination: Engram vs Atlas

Each candidate goes to ONE destination (not both unless there is an explicit reason).

**Atlas — persistent and architectural knowledge** (useful life >6 months, cross-session):
- Lives in `/mnt/nas/Obsidian/` (Obsidian vault). Primary access via filesystem (Read/Write/Edit) — the `atlas_*` MCP may not be available in every session.
- Structure: `Projects/<project>.md` (entity page per project), `Stack/<category>/<tech>.md` (tech reference with `_INDEX.md` master), `Setup/` (infra/operational), `AI/`, `Temp/`.
- "Load-bearing" architecture decisions: stack choice, data model, stable API contracts.
- Organizational conventions that apply across multiple projects.
- Canonical mappings (e.g. "MDASH↔vi-sdd", OWASP taxonomies).
- Established personal/team working patterns.

**Most typical at session close**: if there was a spec/phase close with architectural substance, **update `Projects/<project>.md`** with the delta (current state, metrics, new Stack links). This is usually not a new page — it is an upsert on the existing entity page. Mandatory convention: refresh the `**Last updated:** YYYY-MM-DD` field at the top.

**Engram — operational memory** (useful life weeks-months, day-to-day):
- Resolved bugs (symptom+cause+fix)
- Spec state and metrics (temporal snapshots)
- Specific environment configuration (venv, ports, paths)
- Prioritized technical debt
- Tactical decisions within a spec

**Quick rule**: if the answer to "will this still be true in 6 months?" is YES → atlas. If "it depends on the current state" → engram.

### Step 3 — Check for Duplicates Before Saving

For each candidate:

- Engram: `mem_search("<title or keywords>", project=<X>)`. If something similar exists: use `topic_key` to upsert with `mem_save` or `mem_update`.
- Atlas: check if `Projects/<project>.md` exists in `/mnt/nas/Obsidian/`. If yes → edit the relevant section (do not create a new page). If the observation spans several projects or concerns a technology, consider `Stack/<category>/<tech>.md`. Last resort: create a new page — only if the topic genuinely does not fit any existing one.

`topic_key` values (Engram) must be stable and compound: `vi-sdd/spec-006-owasp`, `homelab/nginx-config`, `personal/git-workflow`.

### Step 4 — Save with Canonical Structure

Mandatory format for `content` (engram and atlas):

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

**Common projects**: `homelab`, `poc-trello`, `openclaw`, `sdd-office`, `vi-sdd`, `engram`.
**Personal scope** (preferred for infra and patterns that apply across projects): `scope: personal`.

Run saves in parallel when they are independent (multiple `mem_save` in a single turn).

### Step 4b — Grafos Memory (if available)

**Only if `grafos_remember` is available**: call it once with a compact session summary:

```
grafos_remember("Session <YYYY-MM-DD> · <project>: <one-line summary of what was done>. Files changed: <list>. Decisions: <list>. Next: <pending item if any>.")
```

This creates graph nodes/edges from the session — allowing `grafos_recall` in future sessions to recover context without reading JSONL. Grafos unavailability is not a blocker — skip gracefully.

### Step 5 — Project Journal (if applicable)

If the project has `docs/journal/sessions/` and the session was substantial (not trivial):

- Check if an entry for today already exists: `docs/journal/sessions/YYYY-MM-DD.md`
- If it does NOT exist and the session warrants an entry: **ask the user** before creating it
  - Template at `docs/journal/sessions/_template.md` if it exists
  - Minimum content: objective, work done, decisions, bugs found, quantified result, state at close
- If it already exists: ask whether to append the advances from this turn
- Do NOT create the journal automatically — always confirm

If the project does NOT have `docs/journal/` → skip this step.

### Step 6 — Summary to User

Display a table of what was saved:

| Destination | Title / Page | Type | Action |
|-------------|-------------|------|--------|
| Engram | ... | bugfix | save |
| Engram | ... | decision | update (#1234) |
| Atlas | `Projects/vi-sdd.md` | architecture | edit (section X) |
| Atlas | `Stack/Languages/Rust.md` | pattern | edit (section Y) |

And briefly mention what was decided NOT to save and why (e.g. "trivial", "already in X").

If a journal was created/modified: include the file path.

---

## Operational Rules

- **Do not invent** observations — only save what actually happened in the conversation.
- **Do not duplicate** — always run `mem_search`/`atlas_search` first. Upsert with `topic_key`.
- **Parallelism**: independent saves go in the same turn.
- **Atlas conservative**: when in doubt, default to Engram. Only to Atlas if the decision is clearly architectural and stable.
- **Respect project language**: if the project's CLAUDE.md is in Spanish, titles and content go in Spanish too.
- **Do not silence errors**: if engram/atlas fails, report to the user what was left pending.

---

## Quick Heuristics

**Is this worth saving?**
- Would you search for this in memory next time you do the same thing? → Yes → save
- Did it take >15 min to resolve or understand? → Yes → save
- Is it something you could forget in 2 weeks? → Yes → save
- Is it already in the code, CLAUDE.md, or docs/? → No → don't save

**Engram or Atlas?**
- "The vi-sdd OWASP catalog maps 19 bug_classes to 7 categories" → atlas (stable taxonomy)
- "Spec 006 closed on May 21 with F1 0.998 and 317 tests" → engram (temporal snapshot)
- "To avoid duplicates, the command-injection-sink dedup omits the symbol" → engram (tactical decision)
- "We use a 6-stage pipeline architecture inspired by MDASH" → atlas (architectural decision)

**Create a journal?**
- Session <30min with no substantial changes → no
- Session with new bug fix, decision, or closed phase → yes (ask first)
- Conversation/analysis only without code → no, but update memory

---

## Compatibility

This skill **replaces** the old `engram-fin-sesion`. If the user invokes that by name, this skill covers the same trigger and adds Atlas + journal.
