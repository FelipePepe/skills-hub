---
name: ddia-batch-processing
description: >
  Guides batch processing, ETL, distributed filesystems, object stores,
  MapReduce-style jobs, dataflow engines, joins, grouping, analytics, machine
  learning preparation, and derived data serving. Trigger: when designing or
  reviewing batch jobs, offline pipelines, ETL/ELT, backfills, analytics jobs,
  data lakes, or large derived datasets.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Designing batch pipelines or backfills.
- Choosing between simple Unix-style processing, distributed jobs, and dataflow engines.
- Reviewing ETL, analytics, ML preparation, or derived-data generation.

## Scope Guard

- Do not use distributed batch engines when one machine and simple tools are enough.
- Do not run destructive backfills without restart and idempotency plans.
- Pair with `ddia-stream-processing` when freshness requirements approach real time.

## Core Rules

- Batch processing is bounded, repeatable work over a known input set.
- Sorting and partitioning often dominate distributed batch cost.
- Object stores and distributed filesystems shape job design and failure recovery.
- Derived outputs should be reproducible from source inputs.

## Workflow

1. Define input datasets, output datasets, and freshness requirements.
2. Decide single-node tools, SQL engine, dataframe engine, or distributed dataflow.
3. Plan joins, grouping, shuffles, and data skew handling.
4. Make outputs idempotent and safe to overwrite or version.
5. Define orchestration, retries, checkpoints, and backfill strategy.
6. Validate lineage and reproducibility.

## Review Checklist

- Can the job resume after partial failure?
- Are inputs immutable or versioned?
- Are joins causing unbounded shuffle or skew?
- Are outputs atomically published?
- Can derived data be rebuilt after corruption or schema change?

## Source Trace

- DDIA 2e Chapter 11: Batch Processing, pages 451-485.
- Key sections: Unix tools; distributed filesystems and object stores; job orchestration; MapReduce and dataflow; batch use cases.
