---
name: ddia-distributed-systems
description: >
  Applies distributed-systems failure thinking: partial failure, unreliable
  networks, timeouts, clocks, process pauses, leases, Byzantine faults, and
  system models. Trigger: when reviewing networked services, timeouts, retries,
  locks, leases, clock assumptions, fault detection, or correctness under
  distributed failure.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Reviewing any design where nodes communicate over a network.
- Debugging timeout, retry, clock, lock, or lease behavior.
- Defining a failure model for distributed correctness.

## Scope Guard

- Do not assume a timeout proves another node is dead.
- Do not rely on wall-clock time unless clock error is bounded and handled.
- Pair with `ddia-consistency-consensus` for consensus and coordination guarantees.

## Core Rules

- Partial failure is normal: some components can fail while others continue.
- Networks can delay, drop, duplicate, or reorder messages.
- Clocks can jump, drift, and disagree; process pauses can invalidate timing assumptions.
- Distributed locks and leases require fencing or equivalent protection.
- State the system model before claiming correctness.

## Workflow

1. List nodes, network calls, storage systems, and external dependencies.
2. For each call, define timeout, retry, idempotency, and unknown outcome behavior.
3. Identify all clock assumptions and replace wall-clock dependency where possible.
4. Define fault detection signals and false-positive consequences.
5. Review locks, leases, and leadership for stale-owner hazards.
6. Add fault injection or randomized testing for critical assumptions.

## Review Checklist

- What happens if a request succeeds but the response is lost?
- Can retries duplicate writes or external side effects?
- Can a paused process resume with stale authority?
- Is majority/quorum logic used correctly?
- Are Byzantine or malicious faults in or out of scope?

## Source Trace

- DDIA 2e Chapter 9: The Trouble with Distributed Systems, pages 345-399.
- Key sections: partial failures; unreliable networks; unreliable clocks; knowledge, truth, and lies.
