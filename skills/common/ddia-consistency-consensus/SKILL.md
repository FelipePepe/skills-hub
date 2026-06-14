---
name: ddia-consistency-consensus
description: >
  Guides consistency and coordination decisions involving linearizability,
  logical clocks, ID generation, consensus, and coordination services. Trigger:
  when a task mentions strong consistency, linearizable reads/writes, global
  ordering, fencing tokens, sequence numbers, consensus, Raft/Paxos, ZooKeeper,
  etcd, or leader election.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Deciding whether a system needs linearizability.
- Designing ID generation, ordering, leader election, or coordination.
- Reviewing consensus-backed services and coordination dependencies.

## Scope Guard

- Do not require linearizability unless the use case needs it.
- Do not use timestamps as unique global ordering without proving assumptions.
- Pair with `ddia-distributed-systems` for network and clock failure analysis.

## Core Rules

- Linearizability makes operations appear to take effect atomically at one point in time.
- Stronger consistency can increase latency and reduce availability under network faults.
- Logical clocks express ordering without relying on physical time.
- Consensus solves agreement but is costly and should be used deliberately.

## Workflow

1. Identify what must be globally unique, ordered, or mutually exclusive.
2. Decide whether stale reads are acceptable.
3. Choose linearizable storage, logical clocks, monotonic IDs, or consensus based on need.
4. Define behavior during partitions and leader changes.
5. Use coordination services for small metadata, not high-volume data paths.
6. Add fencing tokens for externally visible leadership or locks.

## Review Checklist

- Does the invariant require linearizability or only eventual convergence?
- Is the ID generator monotonic, unique, sortable, or all three?
- Can split brain create two active leaders?
- Are coordination dependencies highly available enough for the caller?
- Is consensus hidden in a dependency that now defines system availability?

## Source Trace

- DDIA 2e Chapter 10: Consistency and Consensus, pages 401-449.
- Key sections: linearizability; ID generators and logical clocks; consensus; coordination services.
