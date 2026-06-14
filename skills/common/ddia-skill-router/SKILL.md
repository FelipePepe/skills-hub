---
name: ddia-skill-router
description: >
  Routes data-intensive systems design, review, and planning tasks to the
  appropriate DDIA-derived chapter skill. Trigger: when a task mentions DDIA,
  data-intensive applications, database architecture, distributed data systems,
  data pipelines, consistency, scalability, or system design trade-offs.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Use first when a task spans multiple data-system concerns.
- Use when the right DDIA chapter skill is unclear.
- Use when reviewing architecture for reliability, scalability, maintainability, correctness, or data ethics.

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

## Source Trace

- Source: Designing Data-Intensive Applications, 2nd Edition, table of contents.
- Coverage: Chapters 1-14, pages 1-597.
