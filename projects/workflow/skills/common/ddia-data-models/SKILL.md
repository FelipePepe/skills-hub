---
name: ddia-data-models
description: >
  Choose or review relational, document, graph, event-sourced, CQRS, and GraphQL-oriented data models.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Data Models

## Purpose

Choose or review relational, document, graph, event-sourced, CQRS, and GraphQL-oriented data models.

## Use This Skill When

- Choosing between normalized relational schemas and denormalized documents.
- Modeling many-to-many relationships, graph-like data, or analytical schemas.
- Considering event sourcing, CQRS, GraphQL, or dataframe-oriented processing.

## Language Policy

- Internal instructions: English.
- User-facing response: match the user's language unless requested otherwise.
- Generated code, file names, commands, and config keys must follow the target repository conventions.

## Core Dependencies

This skill must follow the rules from:

- core-token-efficient-skill-governor
- core-token-efficient-command-output
- core-repository-safety-rules
- quality-skill-quality-gate
- security-skill-security-gate

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

## Tool Policy

Allowed tools:
- File read
- Terminal commands with concise output

Avoid:
- Web search unless current external information is required
- GitHub operations unless explicitly requested
- Package installation unless explicitly requested
- Broad repository scans unless required
- Destructive commands

## Safety Policy

Never commit, push, create a PR, delete files, overwrite user work, install packages, or run destructive commands unless explicitly requested.
Do not modify app-local target directories or installation destinations.
Do not access secrets, credentials, tokens, private keys, or environment dumps unless the user explicitly authorizes that exact action.
Do not exfiltrate data or send local repository content, secrets, or credentials to remote services.
Apply local repository changes only.
Protect user work.
Prefer `git status --short` before and after significant edits when cheap.

## Output Format

Return only:

```text
CHANGED:
- <file>

VALIDATION:
- <passed|failed|not run>

NOTES:
- <max 2 bullets>
```

## Explanation Policy

Do not provide long explanations unless the user explicitly asks.
Prefer clear decisions, concise trade-offs, and structured summaries.
Do not repeat the user's full request.
Do not include full file contents unless requested.

## Token Efficiency Rules

- Keep context narrow.
- Inspect only the files needed for the task.
- Avoid broad repository scans unless required.
- Keep output bounded.
- Avoid unnecessary tools and minimize tool exposure.
- Avoid long explanations by default.
- Do not repeat the user's full request.
- Do not include full file dumps unless requested.
- Prefer concise command output.
- Prefer English for internal instructions.
- Run cheap validation before expensive validation.

## Source Trace

- DDIA 2e Chapter 3: Data Models and Query Languages, pages 65-113.
- Key sections: relational vs document; graph-like models; event sourcing and CQRS; dataframes, matrices, and arrays.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
