---
name: ddia-storage-retrieval
description: >
  Review storage engines, indexes, LSM trees, B-trees, column stores, search, and vector retrieval choices.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Storage Retrieval

## Purpose

Review storage engines, indexes, LSM trees, B-trees, column stores, search, and vector retrieval choices.

## Use This Skill When

- Designing indexes or reviewing slow reads and writes.
- Choosing storage layout for OLTP, analytics, search, or embeddings.
- Evaluating columnar storage, materialized views, or in-memory approaches.

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

- Do not add indexes without accounting for write cost and storage amplification.
- Do not compare engines without workload shape.
- Pair with `ddia-nonfunctional-requirements` for latency and throughput targets.

## Core Rules

- B-trees favor ordered lookup and mature general-purpose indexing.
- LSM-style designs trade write path shape, compaction, and read amplification.
- Columnar storage favors analytical scans and compression.
- Materialized views improve reads by moving work to writes or background jobs.
- Search and vector indexes are derived systems that need freshness and rebuild plans.

## Workflow

1. Describe access patterns: point lookup, range scan, aggregation, text search, vector search.
2. Identify read/write ratio, update frequency, dataset size, and freshness need.
3. Select index/storage layout and name the write, read, and space amplification costs.
4. Decide whether data is row-oriented, column-oriented, in-memory, or hybrid.
5. Define maintenance: compaction, rebuilds, vacuuming, statistics, and backfills.
6. Add observability for query plans and storage growth.

## Review Checklist

- Are secondary and multicolumn indexes aligned with real predicates?
- Are covering indexes worth their storage and update cost?
- Are analytical queries isolated from operational load?
- Can materialized views be rebuilt from source data?
- Are full-text and vector results freshness expectations explicit?

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

- DDIA 2e Chapter 4: Storage and Retrieval, pages 115-159.
- Key sections: OLTP storage and indexing; analytics storage; multidimensional, full-text, and vector indexes.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
