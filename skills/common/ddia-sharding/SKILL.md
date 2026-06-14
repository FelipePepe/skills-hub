---
name: ddia-sharding
description: >
  Guides sharding and partitioning decisions for key-value data, multitenancy,
  request routing, hot spots, rebalancing, and secondary indexes. Trigger: when
  a task mentions shards, partitions, tenant isolation, hash partitioning, key
  ranges, hot keys, rebalancing, routing, or global secondary indexes.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Deciding whether and how to shard data.
- Designing tenant placement, hot-spot mitigation, and shard rebalancing.
- Reviewing local vs global secondary indexes.

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

## Source Trace

- DDIA 2e Chapter 7: Sharding, pages 251-275.
- Key sections: multitenancy; key-value sharding; hot spots; routing; secondary indexes.
