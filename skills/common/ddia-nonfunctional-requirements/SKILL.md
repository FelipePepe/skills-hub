---
name: ddia-nonfunctional-requirements
description: >
  Helps define measurable nonfunctional requirements for data-intensive systems:
  performance, reliability, scalability, and maintainability. Trigger: when a
  task mentions latency, response time, percentiles, SLOs, fault tolerance, load,
  scaling, operability, simplicity, or evolvability.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Turning vague quality goals into engineering requirements.
- Reviewing whether a data-system design can meet load and reliability targets.
- Designing or critiquing caches, materialized views, fan-out, and read/write trade-offs.

## Scope Guard

- Do not accept "fast", "reliable", or "scalable" without a metric and workload.
- Do not optimize averages when tail latency matters.
- Do not treat maintainability as secondary to throughput.

## Core Rules

- Define performance using distributions: median, high percentiles, and context.
- Define reliability as correct behavior despite faults, not absence of faults.
- Define scalability by load parameters and bottlenecks.
- Design for operability, simplicity, and evolvability from the start.

## Workflow

1. List functional requirements separately from nonfunctional requirements.
2. Define load: users, records, request rates, fan-out, data size, and growth.
3. Define latency targets with percentiles and user-facing impact.
4. Identify likely hardware, software, dependency, and human faults.
5. Choose scalability strategy and explain what resource it adds.
6. Add operability checks: observability, rollback, automation, and incident handling.

## Review Checklist

- Are response-time targets percentile-based?
- Are spikes, hot keys, and celebrity-style fan-out considered?
- Is derived data used intentionally to shift cost between reads and writes?
- Is the design understandable enough to operate and change?
- Are human mistakes included in the reliability model?

## Source Trace

- DDIA 2e Chapter 2: Defining Nonfunctional Requirements, pages 33-63.
- Key sections: performance; reliability and fault tolerance; scalability; maintainability.
