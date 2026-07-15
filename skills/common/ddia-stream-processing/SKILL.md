---
name: ddia-stream-processing
description: >
  Design and review event streams, brokers, CDC, joins, event time, and stream processing pipelines.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Stream Processing

## Purpose

Design and review event streams, brokers, CDC, joins, event time, and stream processing pipelines.

## Use This Skill When

- Designing event-driven or streaming data pipelines.
- Choosing brokers, logs, CDC, or stream processing semantics.
- Reviewing time handling, state, joins, and failure recovery in streams.

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

- Do not treat "real time" as a requirement without a latency target.
- Do not assume exactly-once behavior without defining the boundary.
- Pair with `ddia-encoding-evolution` for event schemas.

## Core Rules

- Streams are unbounded data; consumers need offset, replay, and retention semantics.
- Log-based brokers support durable replay and multiple derived consumers.
- CDC bridges database writes into event streams but inherits source semantics.
- Event time, processing time, and ingestion time produce different results.
- Stream processors need state recovery and duplicate handling.

## Workflow

1. Define event source, ordering key, retention, replay, and consumer groups.
2. Choose messaging semantics: queue, pub/sub, durable log, or CDC stream.
3. Define event schema, compatibility, and poison-message handling.
4. Identify stateful operations, windows, joins, and late events.
5. Specify fault tolerance: checkpointing, idempotent sinks, transactions, or dedupe.
6. Add lag, throughput, and freshness observability.

## Review Checklist

- Can new consumers replay history?
- Is ordering required globally or per key?
- What happens to late, duplicate, or malformed events?
- Are stream joins bounded and understandable?
- Can sinks tolerate retries after unknown outcomes?

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

- DDIA 2e Chapter 12: Stream Processing, pages 487-537.
- Key sections: event streams; message brokers; databases and streams; CDC; time; joins; fault tolerance.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
