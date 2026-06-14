---
name: ddia-distributed-systems
description: >
  Review partial failures, clocks, timeouts, leases, and fault models in distributed applications.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Distributed Systems

## Purpose

Review partial failures, clocks, timeouts, leases, and fault models in distributed applications.

## Use This Skill When

- Reviewing any design where nodes communicate over a network.
- Debugging timeout, retry, clock, lock, or lease behavior.
- Defining a failure model for distributed correctness.

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

- Do not assume a timeout proves another node is dead.
- Do not rely on wall-clock time unless clock error is bounded and handled.
- Pair with `ddia-consistency-consensus` for consensus and coordination guarantees.

## Core Rules

- Partial failure is normal: some components can fail while others continue.
- Networks can delay, drop, duplicate, or reorder messages.
- Clocks can jump, drift, and disagree; process pauses can invalidate timing assumptions.
- Distributed locks and leases require fencing or equivalent protection.
- State the system model before claiming correctness.

## Workflow

1. List nodes, network calls, storage systems, and external dependencies.
2. For each call, define timeout, retry, idempotency, and unknown outcome behavior.
3. Identify all clock assumptions and replace wall-clock dependency where possible.
4. Define fault detection signals and false-positive consequences.
5. Review locks, leases, and leadership for stale-owner hazards.
6. Add fault injection or randomized testing for critical assumptions.

## Review Checklist

- What happens if a request succeeds but the response is lost?
- Can retries duplicate writes or external side effects?
- Can a paused process resume with stale authority?
- Is majority/quorum logic used correctly?
- Are Byzantine or malicious faults in or out of scope?

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

- DDIA 2e Chapter 9: The Trouble with Distributed Systems, pages 345-399.
- Key sections: partial failures; unreliable networks; unreliable clocks; knowledge, truth, and lies.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
