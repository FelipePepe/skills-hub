---
name: ddia-storage-retrieval
description: >
  Applies storage-engine and retrieval trade-offs for OLTP indexes, analytical
  storage, materialized views, full-text search, and vector indexes. Trigger:
  when choosing indexes, tuning databases, comparing B-trees and LSM trees,
  designing warehouses, or reviewing query performance.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Designing indexes or reviewing slow reads and writes.
- Choosing storage layout for OLTP, analytics, search, or embeddings.
- Evaluating columnar storage, materialized views, or in-memory approaches.

## Scope Guard

- Do not add indexes without accounting for write cost and storage amplification.
- Do not compare engines without workload shape.
- Pair with `ddia-nonfunctional-requirements` for latency and throughput targets.

## Core Rules

- B-trees favor ordered lookup and mature general-purpose indexing.
- LSM-style designs trade write path shape, compaction, and read amplification.
- Columnar storage favors analytical scans and compression.
- Materialized views improve reads by moving work to writes or background jobs.
- Search and vector indexes are derived systems that need freshness and rebuild plans.

## Workflow

1. Describe access patterns: point lookup, range scan, aggregation, text search, vector search.
2. Identify read/write ratio, update frequency, dataset size, and freshness need.
3. Select index/storage layout and name the write, read, and space amplification costs.
4. Decide whether data is row-oriented, column-oriented, in-memory, or hybrid.
5. Define maintenance: compaction, rebuilds, vacuuming, statistics, and backfills.
6. Add observability for query plans and storage growth.

## Review Checklist

- Are secondary and multicolumn indexes aligned with real predicates?
- Are covering indexes worth their storage and update cost?
- Are analytical queries isolated from operational load?
- Can materialized views be rebuilt from source data?
- Are full-text and vector results freshness expectations explicit?

## Source Trace

- DDIA 2e Chapter 4: Storage and Retrieval, pages 115-159.
- Key sections: OLTP storage and indexing; analytics storage; multidimensional, full-text, and vector indexes.
