---
name: ddia-transactions
description: >
  Guides transaction semantics, ACID trade-offs, isolation levels,
  serializability, and distributed transaction decisions. Trigger: when a task
  mentions transactions, atomicity, consistency, isolation, durability, lost
  updates, write skew, phantoms, serializable isolation, two-phase commit, or
  exactly-once processing.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Defining correctness requirements for concurrent reads and writes.
- Choosing or reviewing isolation levels.
- Evaluating distributed transactions or exactly-once workflows.

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

## Source Trace

- DDIA 2e Chapter 8: Transactions, pages 277-343.
- Key sections: ACID; weak isolation; serializability; distributed transactions; exactly-once message processing.
