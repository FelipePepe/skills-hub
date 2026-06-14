---
name: core-grafos-memory
description: Replace file reads with grafos graph recall; persist decisions to survive compaction. Trigger: grafos MCP tools are available in the session.
---

## When to load

Load automatically when `grafos_remember` and `grafos_recall` tools are available.

## Rules

### Before reading a file or exploring the codebase
1. Call `grafos_recall` with the topic or question
2. Only call `Read` / `Bash` if recall returns insufficient context or no results

### After implementing a feature, fixing a bug, or making an architectural decision
Call `grafos_remember` with a concise summary (under 150 words):
- What changed and where (file paths, function names)
- Why (the decision rationale, not the code)

### Before `/compact` or at session end
Call `grafos_remember` with a session summary: decisions made, next steps, blockers.

## Output rules

- Do not re-read files the graph already covers
- One fact or decision per `grafos_remember` call — never dump raw code
- `grafos_recall` results replace context you would have paid Claude tokens to re-derive

## Token impact

Each `grafos_recall` that replaces a `Read` saves the full file's token cost.
Each `grafos_remember` runs through Ollama (local) — zero Claude API tokens consumed.
