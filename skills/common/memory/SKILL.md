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

Agents have no continuity between sessions by default. This harness provides the protocol for persistent memory.

## Backend Detection

| Priority | Backend | When available |
|---|---|---|
| 1 | **Engram** | `mem_save`, `mem_search`, `mem_context` tools |
| 2 | **Filesystem** | Write access to `~/.memory/` |
| 3 | **None** | Warn user |

**Engram is preferred.** Adapt to filesystem or skip if unavailable.

## Compact Protocol

### Session Start (MANDATORY)
1. Call `mem_context` → recover session summary
2. If topic referenced: `mem_search` → `mem_get_observation(id)` (full content, never preview)
3. Brief on last state

### Save Triggers
Call `mem_save` IMMEDIATELY after: architecture decisions, bug fixes, conventions, tool choices, non-obvious discoveries, gotchas, configuration changes, user preferences.

Format:
```
mem_save(
  title: "Verb + what — short, searchable",
  type: "bugfix|decision|architecture|discovery|pattern|config|preference",
  scope: "project|personal",
  topic_key: "stable/key/for-upserts",
  project: "{name}",
  content: "**What**: ...\n**Why**: ...\n**Where**: ...\n**Learned**: ..."
)
```

Topic key rules: same evolving topic → same key (upsert); different → different keys.

### Search Protocol
1. `mem_context` → 2. If not found: `mem_search` → 3. `mem_get_observation(id)` (REQUIRED — never use preview)

### Session Close (MANDATORY)
Call `mem_session_summary` with Goal/Discoveries/Accomplished/Next/Files before ending.

### Compaction Recovery (MANDATORY)
1. IMMEDIATELY `mem_session_summary` with compacted content
2. `mem_context` → recover prior context
3. THEN continue

### Stale Handling
Before recommending from memory: verify file exists or grep function. "Memory says X" ≠ "X exists now."

## What NOT to Save

Code patterns derivable from reading, git history, fixed bugs, doc content, ephemeral task details.
