---
name: openai-docs
description: >
  Use official OpenAI documentation for product, API, model-selection, migration,
  and prompt-upgrade questions. Trigger: When the user asks how to build with
  OpenAI, asks for the latest/current model, requests citations, or needs
  authoritative OpenAI API guidance.
license: Apache-2.0
metadata:
  author: OpenAI / adapted for skills-hub
  version: "1.0"
---

## When to Use

- The user asks about OpenAI APIs, products, SDK usage, or implementation guidance
- The user asks for the latest/current/default OpenAI model
- The user asks for migration guidance between OpenAI models or prompts
- The user wants official citations or docs-backed answers

## Core Rules

1. Prefer official OpenAI docs as the source of truth.
2. Use the OpenAI docs MCP tools first when available.
3. Fall back to web search only on official OpenAI domains.
4. Preserve explicit user targets: if they ask for a named model, do not silently retarget.
5. Keep upgrades narrow: change model strings and directly related prompts only unless the user asks for broader migration work.
6. Do not invent pricing, availability, breaking changes, or API behavior.

## Default Workflow

### 1) Classify the request

- General docs lookup
- Latest/current/default model selection
- Explicit model upgrade
- Prompt upgrade
- Broader API migration

### 2) Fetch the best source

- Search official docs with a precise query
- Fetch the exact page or section needed
- For latest/current/default model questions, check the latest-model guide first

### 3) Answer conservatively

- Cite the official source
- Keep quotes short
- Prefer paraphrase plus links
- If docs are ambiguous, say so explicitly

## Search Order

1. OpenAI docs MCP search/fetch tools
2. Official OpenAI docs pages directly
3. Fallback web search restricted to:
   - `developers.openai.com`
   - `platform.openai.com`

## Upgrade Rules

- If the user asks for "latest/current/default", resolve the latest official guidance first.
- If the user asks for a specific target like `GPT-5.4`, preserve that target.
- Do not broaden scope into SDK, auth, tooling, IDE, or provider migration unless asked.
- If an upgrade requires structural code changes beyond prompt/model edits, stop and report that clearly.

## Fallback Behavior

If the docs MCP is missing or fails:

1. Try installing the OpenAI docs MCP if the environment supports it.
2. If that is blocked, use official OpenAI-domain web search.
3. Clearly disclose when you are using fallback guidance.

## Resources

- Official docs MCP / developer docs
- `https://developers.openai.com/api/docs/guides/latest-model.md`
- Official OpenAI docs search on `developers.openai.com`

## Output contract

Answer the question directly with citation. No preamble.
Format: `[source-url] — {answer}`. If multiple sources: one line per source, then one-line synthesis.
