---
name: ddia-streaming-philosophy
description: >
  Guides architecture around derived data, unbundled databases, dataflow,
  correctness, constraints, timeliness, integrity, and verification. Trigger:
  when composing multiple data systems, designing event-driven architectures,
  syncing derived state, unbundling database responsibilities, or reviewing
  end-to-end data correctness.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Combining specialized tools into one coherent data architecture.
- Designing dataflow-centered applications with multiple derived views.
- Reviewing correctness of asynchronous derived state.

## Scope Guard

- Do not assume eventual consistency is acceptable without user and business impact.
- Do not create derived state without a verification and repair path.
- Pair with `ddia-stream-processing` and `ddia-transactions` for implementation details.

## Core Rules

- Many data systems are specialized indexes or materialized views over shared facts.
- Dataflow makes dependencies explicit and can replace hidden dual writes.
- Correctness requires both timeliness and integrity.
- Trust derived systems, but verify them against authoritative sources.

## Workflow

1. Identify source-of-truth facts and every derived representation.
2. Draw the dataflow graph, including batch, stream, and manual correction paths.
3. Define constraints that must hold across derived systems.
4. Decide where constraints are enforced: source, pipeline, sink, or verifier.
5. Add reconciliation, backfill, and repair procedures.
6. Define freshness SLOs and integrity checks separately.

## Review Checklist

- Are dual writes avoided or made recoverable?
- Can each derived view be rebuilt?
- Are stale reads acceptable and visible?
- Is there a reconciliation process for drift?
- Are constraints enforced close enough to the source of truth?

## Source Trace

- DDIA 2e Chapter 13: A Philosophy of Streaming Systems, pages 539-583.
- Key sections: data integration; unbundling databases; applications around dataflow; correctness; trust but verify.
