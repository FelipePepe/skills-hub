---
name: ddia-encoding-evolution
description: >
  Guides compatible data encoding, schema evolution, service interfaces,
  durable workflows, and event-driven dataflow decisions. Trigger: when changing
  JSON, XML, Protobuf, Avro, database schemas, REST/RPC APIs, workflow payloads,
  or event contracts.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Designing wire formats or stored encodings.
- Evolving APIs, schemas, events, or workflow state without coordinated deploys.
- Reviewing compatibility between producers, consumers, and persisted data.

## Scope Guard

- Do not change a schema without forward and backward compatibility analysis.
- Do not assume all producers and consumers deploy together.
- Pair with `ddia-stream-processing` for event streams and CDC.

## Core Rules

- Compatibility matters across time as much as across services.
- Prefer explicit schemas where long-lived data or multiple languages are involved.
- Treat persisted workflow state and event logs as public contracts.
- Separate semantic changes from encoding changes.

## Workflow

1. Inventory readers, writers, stored data, and replay paths.
2. Classify the format: schemaless text, schema-on-read, or schema-defined binary.
3. Define allowed changes: add field, remove field, rename, type change, default.
4. Plan rolling deploy order for producers and consumers.
5. Validate old data with new code and new data with old code where required.
6. Document versioning, deprecation, and migration policy.

## Review Checklist

- Can older consumers ignore new fields safely?
- Can newer consumers read older records?
- Are required fields and defaults compatible?
- Are API errors and retries defined for RPC/REST boundaries?
- Can durable workflow payloads survive code upgrades?

## Source Trace

- DDIA 2e Chapter 5: Encoding and Evolution, pages 161-195.
- Key sections: encoding formats; schemas; database, service, workflow, and event-driven dataflow.
