---
name: ddia-transactions
description: >
  Review transaction semantics, isolation levels, serializability, anomalies, and distributed transactions.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Transactions

## Purpose

Review transaction semantics, isolation levels, serializability, anomalies, and distributed transactions.

## Use This Skill When

- Defining correctness requirements for concurrent reads and writes.
- Choosing or reviewing isolation levels.
- Evaluating distributed transactions or exactly-once workflows.

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

- Do not equate ACID labels with identical behavior across databases.
- Do not rely on weak isolation without checking lost updates, write skew, and phantoms.
- Pair with `ddia-distributed-systems` for network failure behavior.

## Core Rules

- Transactions are an abstraction for grouping operations despite faults and concurrency.
- Isolation level determines which concurrency anomalies can occur.
- Serializability is strongest but may have performance or availability trade-offs.
- Distributed transactions add blocking, coordination, and operational complexity.

## Workflow

1. Identify invariants that must always hold.
2. Map each invariant to reads and writes that enforce it.
3. Check anomalies possible under the chosen isolation level.
4. Use constraints, locks, compare-and-set, or serializable transactions where needed.
5. For distributed work, compare sagas, idempotency, outbox, and two-phase commit.
6. Define retry behavior and external side-effect handling.

## Review Checklist

- Can two concurrent operations violate a business invariant?
- Are lost updates prevented?
- Can write skew happen under snapshot isolation?
- Are transaction boundaries too broad or too narrow?
- Are retries idempotent and safe after unknown commit outcomes?

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

- DDIA 2e Chapter 8: Transactions, pages 277-343.
- Key sections: ACID; weak isolation; serializability; distributed transactions; exactly-once message processing.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
