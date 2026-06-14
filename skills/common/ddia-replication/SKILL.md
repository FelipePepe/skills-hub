---
name: ddia-replication
description: >
  Guides replication design and review across single-leader, multi-leader,
  leaderless, geographically distributed, and local-first systems. Trigger:
  when a task mentions replicas, followers, failover, replication lag, read
  your writes, conflicts, quorum, multi-region, sync engines, or offline edits.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Choosing a replication topology.
- Reviewing failover, lag, conflict handling, or multi-region behavior.
- Designing sync engines or local-first application data flows.

## Scope Guard

- Do not promise fresh reads from asynchronous replicas.
- Do not ignore conflict resolution in multi-writer systems.
- Pair with `ddia-consistency-consensus` when coordination guarantees are required.

## Core Rules

- Single-leader replication simplifies writes but creates failover and lag concerns.
- Asynchronous replication improves availability and latency but can lose recent writes.
- Multi-leader and leaderless designs require explicit conflict semantics.
- User-facing consistency often needs read-your-writes and monotonic-read strategies.

## Workflow

1. Define why replication is needed: availability, read scaling, latency, geography, offline use.
2. Choose topology: single-leader, multi-leader, leaderless, or local-first.
3. Define sync mode, failover behavior, and data-loss tolerance.
4. Identify user-visible anomalies from lag and mitigation strategies.
5. Specify conflict detection, merge rules, and auditability.
6. Add operational checks for lag, replica health, and recovery.

## Review Checklist

- Is failover automatic, manual, or intentionally absent?
- What happens to acknowledged writes during leader failure?
- Can users see stale data after their own writes?
- Are concurrent writes detected and resolved deterministically?
- Are new replicas bootstrapped without corrupting source data?

## Source Trace

- DDIA 2e Chapter 6: Replication, pages 197-249.
- Key sections: single-leader; multi-leader; sync engines and local-first; leaderless replication; conflicts.
