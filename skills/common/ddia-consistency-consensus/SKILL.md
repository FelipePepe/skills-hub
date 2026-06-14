---
name: ddia-consistency-consensus
description: >
  Review consistency, linearizability, ordering, coordination, and consensus choices in distributed systems.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Consistency Consensus

## Purpose

Review consistency, linearizability, ordering, coordination, and consensus choices in distributed systems.

## Use This Skill When

- Deciding whether a system needs linearizability.
- Designing ID generation, ordering, leader election, or coordination.
- Reviewing consensus-backed services and coordination dependencies.

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

- Do not require linearizability unless the use case needs it.
- Do not use timestamps as unique global ordering without proving assumptions.
- Pair with `ddia-distributed-systems` for network and clock failure analysis.

## Core Rules

- Linearizability makes operations appear to take effect atomically at one point in time.
- Stronger consistency can increase latency and reduce availability under network faults.
- Logical clocks express ordering without relying on physical time.
- Consensus solves agreement but is costly and should be used deliberately.

## Workflow

1. Identify what must be globally unique, ordered, or mutually exclusive.
2. Decide whether stale reads are acceptable.
3. Choose linearizable storage, logical clocks, monotonic IDs, or consensus based on need.
4. Define behavior during partitions and leader changes.
5. Use coordination services for small metadata, not high-volume data paths.
6. Add fencing tokens for externally visible leadership or locks.

## Review Checklist

- Does the invariant require linearizability or only eventual convergence?
- Is the ID generator monotonic, unique, sortable, or all three?
- Can split brain create two active leaders?
- Are coordination dependencies highly available enough for the caller?
- Is consensus hidden in a dependency that now defines system availability?

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

- DDIA 2e Chapter 10: Consistency and Consensus, pages 401-449.
- Key sections: linearizability; ID generators and logical clocks; consensus; coordination services.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
