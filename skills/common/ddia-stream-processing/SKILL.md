---
name: ddia-stream-processing
description: >
  Guides event stream design with messaging systems, log-based brokers,
  databases and streams, change data capture, event time, stream joins, state,
  and fault tolerance. Trigger: when designing or reviewing Kafka-like logs,
  pub/sub, CDC, stream processors, event-time windows, stream joins, or
  real-time pipelines.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Designing event-driven or streaming data pipelines.
- Choosing brokers, logs, CDC, or stream processing semantics.
- Reviewing time handling, state, joins, and failure recovery in streams.

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

## Source Trace

- DDIA 2e Chapter 12: Stream Processing, pages 487-537.
- Key sections: event streams; message brokers; databases and streams; CDC; time; joins; fault tolerance.
