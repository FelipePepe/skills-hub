---
name: ddia-data-models
description: >
  Guides selection and review of data models and query languages, including
  relational, document, graph, event-sourced, CQRS, GraphQL, dataframe, matrix,
  and array-oriented models. Trigger: when designing schemas, APIs, relationships,
  joins, graph queries, analytics schemas, or model boundaries.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Choosing between normalized relational schemas and denormalized documents.
- Modeling many-to-many relationships, graph-like data, or analytical schemas.
- Considering event sourcing, CQRS, GraphQL, or dataframe-oriented processing.

## Scope Guard

- Do not choose a model by trend or database brand.
- Do not denormalize without an update and consistency strategy.
- Pair with `ddia-storage-retrieval` when physical access patterns dominate.

## Core Rules

- Model the data around relationships, query patterns, and change patterns.
- Prefer normalization when many records refer to the same evolving fact.
- Prefer document locality when data is usually loaded and updated as a unit.
- Use graph models when relationships are first-class and traversal depth matters.
- Treat API query languages as contracts that affect evolvability.

## Workflow

1. Identify entities, relationships, cardinality, and ownership.
2. List read and write paths, including analytical access.
3. Decide where joins happen: database, application, pipeline, or precomputed view.
4. Evaluate schema evolution and compatibility pressure.
5. For event sourcing or CQRS, define event log, projections, replay, and correction model.
6. Document the trade-off between local reads, duplicated data, and update complexity.

## Review Checklist

- Are many-to-one and many-to-many relationships represented without hidden duplication bugs?
- Are analytical star or snowflake schemas separated from OLTP schemas when needed?
- Does graph usage require graph traversal, or only nested objects?
- Can historical events be replayed safely if CQRS/event sourcing is used?
- Does GraphQL expose a maintainable boundary or create unbounded query cost?

## Source Trace

- DDIA 2e Chapter 3: Data Models and Query Languages, pages 65-113.
- Key sections: relational vs document; graph-like models; event sourcing and CQRS; dataframes, matrices, and arrays.
