---
name: ddia-architecture-tradeoffs
description: >
  Guides data-system architecture trade-off decisions across operational vs
  analytical systems, cloud vs self-hosting, and distributed vs single-node
  designs. Trigger: when choosing database architecture, service boundaries,
  cloud services, data warehouses, data lakes, or distributed deployment shape.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Choosing OLTP, OLAP, HTAP, warehouse, lake, or derived-data architecture.
- Deciding whether to use managed cloud services or self-hosted systems.
- Deciding whether a workload needs distribution or can remain single-node.

## Scope Guard

- Do not recommend distributed systems by default.
- Do not treat cloud services as automatically cheaper, easier, or safer.
- Pair with `ddia-nonfunctional-requirements` when requirements are vague.

## Core Rules

- Separate systems of record from derived data unless the design deliberately combines them.
- Match operational systems to low-latency point reads/writes; match analytical systems to scans, aggregation, and exploration.
- Use distribution for concrete needs: availability, scale, latency, elasticity, legal placement, or specialized hardware.
- Count operational control, vendor lock-in, cost visibility, and debugging access as first-class trade-offs.

## Workflow

1. Classify the workload: operational, analytical, hybrid, or pipeline.
2. Identify systems of record and every derived data copy.
3. Decide whether the workload fits one node before adding distribution.
4. Compare cloud service, self-hosted managed software, and custom implementation.
5. Document who operates each component and how failures are diagnosed.

## Review Checklist

- Is every data copy labeled authoritative or derived?
- Can expensive analytical work harm user-facing operations?
- Are cloud quotas, cost drivers, and vendor lock-in risks visible?
- Is the distribution rationale explicit and measurable?
- Are legal, privacy, and user-rights constraints surfaced?

## Source Trace

- DDIA 2e Chapter 1: Trade-Offs in Data Systems Architecture, pages 1-31.
- Key sections: operational vs analytical systems; cloud vs self-hosting; distributed vs single-node systems; law and society.
