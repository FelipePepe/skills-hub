---
name: headroom
description: "Compress verbose content (large outputs, files, diffs, logs) to save context; retrieve originals by hash. Trigger: large reads or results, 'compress this', 'save context', headroom stats."
---

# Headroom — Context Compression

Shrinks large text before it enters the context window, and lets you pull the original back by hash when you actually need the full detail.

## 3 MCP Tools

| Tool | Use |
|------|-----|
| `headroom_compress(content)` | Compress large text. Returns compressed text + a retrieval hash. |
| `headroom_retrieve(hash)` | Get the original uncompressed content back by hash. |
| `headroom_stats()` | Session totals: compressions, tokens saved, estimated cost savings. |

## When to Compress

- Roughly >200 lines, or clearly verbose (long diff, log/error dump, large doc, wide query result) → compress before reasoning over it or saving it elsewhere.
- A handful of lines / a targeted snippet → don't bother; compressing costs more than it saves.
- Compress once per piece of content — don't re-compress an already-compressed result.

## When to Retrieve

- You (or a downstream save) need the full untruncated original, not the summary — call `headroom_retrieve(hash)` using the hash from the original `headroom_compress` call or from a `[N items compressed... hash=abc123]` marker.
- If a compressed version of the same content already exists earlier in the session, prefer retrieving it over re-reading and re-compressing the source.

## How It's Used Elsewhere

- **session-start**: compresses large state docs (`docs/STATE.md`, `IMPLEMENTATION_SUMMARY.md`, journal entries) before loading them into the briefing.
- **session-end**: compresses verbose source material (long diffs, log dumps) before deriving Engram/Atlas observation content from it.
- **codebase-memory**: compresses large `query_graph`/`get_architecture`/`search_code` payloads before carrying them forward in context.
- **engram** (`memory` skill): compresses verbose source material before writing it into a `mem_save` `content` field.

## Gotchas

1. Compression is lossy for reasoning purposes — always keep the hash so the original is recoverable if a decision later needs the raw detail.
2. `headroom_stats` reports session-scoped totals, not persistent history — don't treat it as a cross-session log.
3. If headroom is unavailable, every caller above falls back to the raw content — it's a best-effort optimization, never a blocker.
