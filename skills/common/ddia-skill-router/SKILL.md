---
name: ddia-skill-router
description: >
  Route DDIA/data-intensive system design questions to the most specific DDIA chapter skill.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Skill Router

## Purpose

Route DDIA/data-intensive system design questions to the most specific DDIA chapter skill.

## Use This Skill When

- Use first when a task spans multiple data-system concerns.
- Use when the right DDIA chapter skill is unclear.
- Use when reviewing architecture for reliability, scalability, maintainability, correctness, or data ethics.

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

- This skill routes to focused skills; it is not a substitute for a full architecture review.
- Do not quote or summarize the book at length. Load chapter skills for operational guidance.

## Core Rules

- Prefer the most specific chapter skill that matches the dominant design risk.
- Load multiple DDIA skills only when the task genuinely crosses chapter boundaries.
- Keep DDIA-derived outputs operational: decisions, trade-offs, checklists, and review questions.
- Preserve the shared chapter skill structure: When to Use, Scope Guard, Core Rules, Workflow, Review Checklist, Source Trace.

## Routing Table

| Task Signal | Load |
|---|---|
| OLTP vs OLAP, cloud vs self-hosted, distributed vs single-node | `ddia-architecture-tradeoffs` |
| latency, percentiles, fault tolerance, load, maintainability | `ddia-nonfunctional-requirements` |
| relational, document, graph, event sourcing, CQRS, GraphQL | `ddia-data-models` |
| indexes, LSM, B-tree, column storage, search, vector index | `ddia-storage-retrieval` |
| JSON, Protobuf, Avro, schema evolution, REST, RPC, workflows | `ddia-encoding-evolution` |
| leader, follower, replication lag, conflict resolution, local-first | `ddia-replication` |
| partitioning, sharding, hot spots, request routing, secondary indexes | `ddia-sharding` |
| ACID, isolation, serializability, distributed transactions | `ddia-transactions` |
| partial failure, timeouts, clocks, leases, Byzantine faults | `ddia-distributed-systems` |
| linearizability, logical clocks, consensus, coordination services | `ddia-consistency-consensus` |
| ETL, batch jobs, object stores, MapReduce, dataflow engines | `ddia-batch-processing` |
| brokers, CDC, event streams, stream joins, event time | `ddia-stream-processing` |
| derived data, unbundled databases, dataflow correctness | `ddia-streaming-philosophy` |
| predictive analytics, privacy, tracking, consent, accountability | `ddia-data-ethics` |

## Workflow

1. Identify the dominant design question.
2. Load the most specific DDIA skill from the routing table.
3. If the task crosses boundaries, load at most three chapter skills and state the order.
4. Produce decisions as trade-offs, not universal rules.
5. Call out assumptions about workload, failure model, consistency needs, and operational ownership.

## Review Checklist

- Are operational and analytical needs separated where appropriate?
- Are nonfunctional requirements measurable?
- Are data model, storage, replication, and processing choices aligned with access patterns?
- Are distributed-system failure modes explicit?
- Are privacy, consent, and accountability considered for personal data or predictive systems?

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

- Source: Designing Data-Intensive Applications, 2nd Edition, table of contents.
- Coverage: Chapters 1-14, pages 1-597.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
