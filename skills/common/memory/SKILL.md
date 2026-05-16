---
name: memory
description: >
  Persistent memory harness — cross-session knowledge persistence using a pluggable
  memory backend (Engram, filesystem, or none). Manages decisions, discoveries,
  session summaries, bug fixes, and progressive context recovery.
  Trigger: any session start, compaction recovery, "remember X", "recall X",
  "what did we do", or any reference to past work.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  version: "1.0"
  harness: agnostic
---

## Harness #10: Memory

Agents have no continuity between sessions by default. Without a memory backend, every session starts cold — rediscovering decisions, conventions, bugs already fixed, and context already built. That is expensive in tokens, time, and frustration.

This harness defines the protocol for persistent memory regardless of the backend.

## Backend Detection

Detect the available backend at session start:

| Priority | Backend | Available when |
|---|---|---|
| 1 | **Engram** | `mem_save`, `mem_search`, `mem_context` tools are available |
| 2 | **Filesystem** | Write access to `~/.memory/` or `./.memory/` |
| 3 | **None** | No persistence possible — warn user |

**Engram** is the preferred backend. All protocol steps below use Engram as the reference. If Engram is unavailable, adapt to filesystem (markdown files) or operate without persistence.

## Session Start Protocol (MANDATORY)

On EVERY session start:

1. Call `mem_context` — recovers the most recent session summary (fast, cheap)
2. If no summary found or topic is referenced: call `mem_search` with relevant keywords
3. If found: call `mem_get_observation(id)` for the full untruncated content
4. Brief the agent on what was last done and what is next

This prevents cold starts. The agent picks up where the last session left off.

## Proactive Save Triggers

Call `mem_save` IMMEDIATELY and WITHOUT BEING ASKED after any of these:

- Architecture or design decision made
- Bug fix completed (include root cause + where)
- Team convention documented or established
- Workflow or tool choice made with tradeoffs
- Non-obvious discovery about the codebase
- Gotcha, edge case, or unexpected behavior found
- Pattern established (naming, structure, convention)
- Feature implemented with non-obvious approach
- Configuration change or environment setup done
- User preference or constraint learned

**Self-check after every task**: "Did I make a decision, fix a bug, learn something non-obvious, or establish a convention? If yes → `mem_save` NOW."

## Save Format

```
mem_save(
  title:     "Verb + what — short, searchable",
  type:      "bugfix | decision | architecture | discovery | pattern | config | preference",
  scope:     "project | personal",
  topic_key: "stable/key/for-upserts",  -- optional but recommended for evolving topics
  project:   "{project-name}",
  content:   "
    **What**: One sentence — what was done.
    **Why**: What motivated it (user request, bug, performance, compliance).
    **Where**: Files or paths affected.
    **Learned**: Gotchas, edge cases, surprises. Omit if none.
  "
)
```

**Topic key rules:**
- Same topic evolving → same `topic_key` (upsert, not duplicate)
- Different topics → different keys, even if related
- Unsure → call `mem_suggest_topic_key` first

## Search Protocol

On any "remember", "recall", "what did we do", "how did we solve", or reference to past work:

1. `mem_context` — check recent session history (fast)
2. If not found: `mem_search(query: "{keywords}")` → save the ID
3. `mem_get_observation(id: {id})` — get full content (REQUIRED — search returns 300-char previews)

**Never use search previews as source material.** Always retrieve the full observation.

## Session Close Protocol (MANDATORY)

Before ending a session or saying "done / listo / that's it", save a session summary:

```
mem_session_summary(
  content: "
    ## Goal
    [What we were working on this session]

    ## Discoveries
    - [Technical findings, gotchas, non-obvious learnings]

    ## Accomplished
    - [Completed items with key details]

    ## Next Steps
    - [What remains — for the next session]

    ## Relevant Files
    - path/to/file — [what changed or why it matters]
  "
)
```

This is NOT optional. Without it, the next session starts blind.

## Compaction Recovery (MANDATORY)

If a compaction message appears or "FIRST ACTION REQUIRED" is detected:

1. IMMEDIATELY call `mem_session_summary` with the compacted summary content — preserves what was done before compaction
2. Call `mem_context` — recovers prior context
3. Only THEN continue working

Do not skip step 1. Everything done before compaction is lost from memory without it.

## Memory Index (Filesystem Backend)

When using filesystem instead of Engram, store memories as markdown files:

```
~/.memory/
├── MEMORY.md          — index (one line per entry, max 200 lines)
├── user-{slug}.md     — user preferences and role
├── feedback-{slug}.md — workflow corrections and validations
├── project-{slug}.md  — project context, goals, decisions
└── reference-{slug}.md — pointers to external resources
```

Each file uses this frontmatter:
```yaml
---
name: short-kebab-slug
description: one-line summary (used for relevance matching)
metadata:
  type: user | feedback | project | reference
---
```

## What NOT to Save

Do not save:
- Code patterns or architecture derivable from reading the code
- Git history (use `git log` / `git blame`)
- Debugging steps that are now fixed (the fix is in the code)
- Anything already in CLAUDE.md or project docs
- Ephemeral task details or current conversation context

## Stale Memory Handling

Before recommending anything from memory:
- If memory names a file path: verify the file exists
- If memory names a function or flag: grep for it
- If user asks about current state: prefer `git log` over memory snapshots

"The memory says X exists" ≠ "X exists now."

## Cross-Agent Sharing

Memory is shared across agents using the same backend (Engram DB or filesystem path). This enables:
- Orchestrator and sub-agents sharing discoveries
- Pi and Claude Code reading the same Engram DB
- OpenCode accessing session summaries from prior Claude Code sessions

**Sub-agents that discover something must save it before returning.** The orchestrator will not know what the sub-agent learned unless it is persisted.
