---
name: grafos-memory
description: >
  Persistent graph memory shared across sessions and assistants on this machine
  via the grafos MCP server (grafos_remember / grafos_recall). Trigger: BEFORE answering
  questions about prior decisions, ownership, conventions, or project context
  ("why did we...", "who owns...", "what do we know about..."), and AFTER
  learning a durable fact (architecture decision with its reason, bug cause and
  fix, team convention, component relationship).
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---

# grafos-memory

grafos stores entities and typed relations in a local knowledge graph
(`~/.grafos/memory.db`) and retrieves them as compact triples. One `grafos_recall`
costs a few hundred tokens; re-deriving the same context by re-reading files costs
thousands. Prefer recall first.

## When to recall

Call `grafos_recall(query)` BEFORE answering, when the question may depend on
knowledge from past sessions:

- "Why was X designed this way?" → `grafos_recall("X architecture decision")`
- "Who works on / owns X?" → `grafos_recall("X ownership")`
- "What do we know about X?" → `grafos_recall("X")`
- Starting work in a known project → recall the project name first.

Use natural-language queries, not keywords. An empty result means nothing is
stored — proceed normally, do not retry with variations.

## When to remember

Call `grafos_remember(text)` AFTER learning something worth keeping across
sessions:

- Architecture decisions **and the reason behind them**
- Bug root causes and their fixes
- Team or project conventions
- Ownership and relationships between components, people, services

Write one self-contained natural-language sentence per fact, naming entities
explicitly ("The grafos MCP package compiles with rootDir '..' because it
imports the library source directly"). Repeated text is deduplicated server-side
— remembering twice is free, so do not track what you already stored.

## Do NOT remember

- Secrets, API keys, tokens, credentials (house rule: secrets live in Infisical)
- Transient state (current branch, today's failing test, in-progress edits)
- Anything the repo already records (code structure, git history, CLAUDE.md)

## Setup (once per machine)

The server registration is distributed by skills-hub managed config
(`pnpm skills-hub install`). Requirements on each machine:

- grafos cloned at `~/sources/grafos` and built (`cd mcp && pnpm install && pnpm build`)
- Node 22+ (`node:sqlite`)
- Claude Code: export `ANTHROPIC_API_KEY` and `VOYAGE_API_KEY` in the shell
  environment (the server inherits them; they are never written to config)
- VS Code: keys are prompted on first start via `inputs` and stored securely

The database is per machine and must live on local disk, never on the NAS.
