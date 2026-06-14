---
name: ddia-sharding
description: >
  Review partitioning, sharding, hot spots, routing, secondary indexes, and rebalance strategies.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Sharding

## Purpose

Review partitioning, sharding, hot spots, routing, secondary indexes, and rebalance strategies.

## Use This Skill When

- Deciding whether and how to shard data.
- Designing tenant placement, hot-spot mitigation, and shard rebalancing.
- Reviewing local vs global secondary indexes.

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

- Do not shard before a single-node or simpler replicated design is insufficient.
- Do not hash keys if range scans are central without planning alternatives.
- Pair with `ddia-replication` when shards are also replicated.

## Core Rules

- Sharding spreads data and load but increases routing and operational complexity.
- Key-range sharding supports ordered access but risks skew.
- Hash sharding spreads keys but makes range queries harder.
- Secondary indexes are harder in sharded systems; choose local or global intentionally.

## Workflow

1. Define the bottleneck that sharding should solve.
2. Choose shard key from access patterns and tenant boundaries.
3. Evaluate key-range, hash, or hybrid partitioning.
4. Plan hot-spot detection and relief.
5. Define routing, metadata ownership, and rebalancing process.
6. Decide local vs global secondary index behavior and consistency.

## Review Checklist

- Is shard key cardinality high enough?
- Can the design survive a hot tenant or hot key?
- Are cross-shard queries and transactions acceptable?
- Is rebalancing automatic, manual, or operator-driven?
- Are secondary indexes queryable without hidden fan-out explosions?

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

- DDIA 2e Chapter 7: Sharding, pages 251-275.
- Key sections: multitenancy; key-value sharding; hot spots; routing; secondary indexes.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
