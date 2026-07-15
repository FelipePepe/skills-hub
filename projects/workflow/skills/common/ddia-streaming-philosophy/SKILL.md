---
name: ddia-streaming-philosophy
description: >
  Review derived data, unbundled databases, dataflow correctness, and stream-oriented architecture.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Streaming Philosophy

## Purpose

Review derived data, unbundled databases, dataflow correctness, and stream-oriented architecture.

## Use This Skill When

- Combining specialized tools into one coherent data architecture.
- Designing dataflow-centered applications with multiple derived views.
- Reviewing correctness of asynchronous derived state.

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

- Do not assume eventual consistency is acceptable without user and business impact.
- Do not create derived state without a verification and repair path.
- Pair with `ddia-stream-processing` and `ddia-transactions` for implementation details.

## Core Rules

- Many data systems are specialized indexes or materialized views over shared facts.
- Dataflow makes dependencies explicit and can replace hidden dual writes.
- Correctness requires both timeliness and integrity.
- Trust derived systems, but verify them against authoritative sources.

## Workflow

1. Identify source-of-truth facts and every derived representation.
2. Draw the dataflow graph, including batch, stream, and manual correction paths.
3. Define constraints that must hold across derived systems.
4. Decide where constraints are enforced: source, pipeline, sink, or verifier.
5. Add reconciliation, backfill, and repair procedures.
6. Define freshness SLOs and integrity checks separately.

## Review Checklist

- Are dual writes avoided or made recoverable?
- Can each derived view be rebuilt?
- Are stale reads acceptable and visible?
- Is there a reconciliation process for drift?
- Are constraints enforced close enough to the source of truth?

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

- DDIA 2e Chapter 13: A Philosophy of Streaming Systems, pages 539-583.
- Key sections: data integration; unbundling databases; applications around dataflow; correctness; trust but verify.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
