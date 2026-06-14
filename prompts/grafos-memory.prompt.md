# Grafos Graph Memory

Use the `grafos_remember` and `grafos_recall` MCP tools to reduce token usage and persist knowledge across sessions.

## Rules

**Before reading a file or searching the codebase:**
Call `grafos_recall` with the topic first. Only read files if recall returns no useful results.

**After writing or editing code:**
Call `grafos_remember` with a concise summary of what changed and why (file path + decision rationale, under 150 words). Never dump raw code.

**Before ending a session or when context is getting long:**
Call `grafos_remember` with a session summary covering decisions made and next steps.

## Why

- `grafos_recall` replaces expensive file reads — graph traversal returns connected facts, not just matches
- `grafos_remember` runs through local Ollama — zero API tokens consumed
- Knowledge persists across sessions and survives `/compact`
