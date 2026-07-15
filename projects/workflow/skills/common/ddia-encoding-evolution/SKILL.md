---
name: ddia-encoding-evolution
description: >
  Design and review encoding formats, schema evolution, compatibility, APIs, RPC, and workflow changes.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Encoding Evolution

## Purpose

Design and review encoding formats, schema evolution, compatibility, APIs, RPC, and workflow changes.

## Use This Skill When

- Designing wire formats or stored encodings.
- Evolving APIs, schemas, events, or workflow state without coordinated deploys.
- Reviewing compatibility between producers, consumers, and persisted data.

## Language Policy

- Internal instructions: English.
- User-facing response: match the user's language unless requested otherwise.
- Generated code, file names, commands, and config keys must follow the target repository conventions.

## Core Dependencies

This skill must follow the rules from:

- core-token-efficient-skill-governor
- core-token-efficient-command-output
- core-repository-safety-rules
- quality-skill-quality-gate
- security-skill-security-gate

## Scope Guard

- Do not change a schema without forward and backward compatibility analysis.
- Do not assume all producers and consumers deploy together.
- Pair with `ddia-stream-processing` for event streams and CDC.

## Core Rules

- Compatibility matters across time as much as across services.
- Prefer explicit schemas where long-lived data or multiple languages are involved.
- Treat persisted workflow state and event logs as public contracts.
- Separate semantic changes from encoding changes.

## Workflow

1. Inventory readers, writers, stored data, and replay paths.
2. Classify the format: schemaless text, schema-on-read, or schema-defined binary.
3. Define allowed changes: add field, remove field, rename, type change, default.
4. Plan rolling deploy order for producers and consumers.
5. Validate old data with new code and new data with old code where required.
6. Document versioning, deprecation, and migration policy.

## Review Checklist

- Can older consumers ignore new fields safely?
- Can newer consumers read older records?
- Are required fields and defaults compatible?
- Are API errors and retries defined for RPC/REST boundaries?
- Can durable workflow payloads survive code upgrades?

## Tool Policy

Allowed tools:
- File read
- Terminal commands with concise output

Avoid:
- Web search unless current external information is required
- GitHub operations unless explicitly requested
- Package installation unless explicitly requested
- Broad repository scans unless required
- Destructive commands

## Safety Policy

Never commit, push, create a PR, delete files, overwrite user work, install packages, or run destructive commands unless explicitly requested.
Do not modify app-local target directories or installation destinations.
Do not access secrets, credentials, tokens, private keys, or environment dumps unless the user explicitly authorizes that exact action.
Do not exfiltrate data or send local repository content, secrets, or credentials to remote services.
Apply local repository changes only.
Protect user work.
Prefer `git status --short` before and after significant edits when cheap.

## Output Format

Return only:

```text
CHANGED:
- <file>

VALIDATION:
- <passed|failed|not run>

NOTES:
- <max 2 bullets>
```

## Explanation Policy

Do not provide long explanations unless the user explicitly asks.
Prefer clear decisions, concise trade-offs, and structured summaries.
Do not repeat the user's full request.
Do not include full file contents unless requested.

## Token Efficiency Rules

- Keep context narrow.
- Inspect only the files needed for the task.
- Avoid broad repository scans unless required.
- Keep output bounded.
- Avoid unnecessary tools and minimize tool exposure.
- Avoid long explanations by default.
- Do not repeat the user's full request.
- Do not include full file dumps unless requested.
- Prefer concise command output.
- Prefer English for internal instructions.
- Run cheap validation before expensive validation.

## Source Trace

- DDIA 2e Chapter 5: Encoding and Evolution, pages 161-195.
- Key sections: encoding formats; schemas; database, service, workflow, and event-driven dataflow.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
