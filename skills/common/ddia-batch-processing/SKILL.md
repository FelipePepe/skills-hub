---
name: ddia-batch-processing
description: >
  Design and review batch data pipelines, ETL jobs, materialized views, and offline analytics workflows.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Batch Processing

## Purpose

Design and review batch data pipelines, ETL jobs, materialized views, and offline analytics workflows.

## Use This Skill When

- Designing batch pipelines or backfills.
- Choosing between simple Unix-style processing, distributed jobs, and dataflow engines.
- Reviewing ETL, analytics, ML preparation, or derived-data generation.

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

- Do not use distributed batch engines when one machine and simple tools are enough.
- Do not run destructive backfills without restart and idempotency plans.
- Pair with `ddia-stream-processing` when freshness requirements approach real time.

## Core Rules

- Batch processing is bounded, repeatable work over a known input set.
- Sorting and partitioning often dominate distributed batch cost.
- Object stores and distributed filesystems shape job design and failure recovery.
- Derived outputs should be reproducible from source inputs.

## Workflow

1. Define input datasets, output datasets, and freshness requirements.
2. Decide single-node tools, SQL engine, dataframe engine, or distributed dataflow.
3. Plan joins, grouping, shuffles, and data skew handling.
4. Make outputs idempotent and safe to overwrite or version.
5. Define orchestration, retries, checkpoints, and backfill strategy.
6. Validate lineage and reproducibility.

## Review Checklist

- Can the job resume after partial failure?
- Are inputs immutable or versioned?
- Are joins causing unbounded shuffle or skew?
- Are outputs atomically published?
- Can derived data be rebuilt after corruption or schema change?

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

- DDIA 2e Chapter 11: Batch Processing, pages 451-485.
- Key sections: Unix tools; distributed filesystems and object stores; job orchestration; MapReduce and dataflow; batch use cases.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
