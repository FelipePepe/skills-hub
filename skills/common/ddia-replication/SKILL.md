---
name: ddia-replication
description: >
  Review leader/follower replication, lag, failover, conflict handling, and local-first synchronization.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Replication

## Purpose

Review leader/follower replication, lag, failover, conflict handling, and local-first synchronization.

## Use This Skill When

- Choosing a replication topology.
- Reviewing failover, lag, conflict handling, or multi-region behavior.
- Designing sync engines or local-first application data flows.

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

- Do not promise fresh reads from asynchronous replicas.
- Do not ignore conflict resolution in multi-writer systems.
- Pair with `ddia-consistency-consensus` when coordination guarantees are required.

## Core Rules

- Single-leader replication simplifies writes but creates failover and lag concerns.
- Asynchronous replication improves availability and latency but can lose recent writes.
- Multi-leader and leaderless designs require explicit conflict semantics.
- User-facing consistency often needs read-your-writes and monotonic-read strategies.

## Workflow

1. Define why replication is needed: availability, read scaling, latency, geography, offline use.
2. Choose topology: single-leader, multi-leader, leaderless, or local-first.
3. Define sync mode, failover behavior, and data-loss tolerance.
4. Identify user-visible anomalies from lag and mitigation strategies.
5. Specify conflict detection, merge rules, and auditability.
6. Add operational checks for lag, replica health, and recovery.

## Review Checklist

- Is failover automatic, manual, or intentionally absent?
- What happens to acknowledged writes during leader failure?
- Can users see stale data after their own writes?
- Are concurrent writes detected and resolved deterministically?
- Are new replicas bootstrapped without corrupting source data?

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

- DDIA 2e Chapter 6: Replication, pages 197-249.
- Key sections: single-leader; multi-leader; sync engines and local-first; leaderless replication; conflicts.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
