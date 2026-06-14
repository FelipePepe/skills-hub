---
name: ddia-nonfunctional-requirements
description: >
  Define measurable reliability, scalability, latency, load, operability, and maintainability requirements.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Nonfunctional Requirements

## Purpose

Define measurable reliability, scalability, latency, load, operability, and maintainability requirements.

## Use This Skill When

- Turning vague quality goals into engineering requirements.
- Reviewing whether a data-system design can meet load and reliability targets.
- Designing or critiquing caches, materialized views, fan-out, and read/write trade-offs.

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

- Do not accept "fast", "reliable", or "scalable" without a metric and workload.
- Do not optimize averages when tail latency matters.
- Do not treat maintainability as secondary to throughput.

## Core Rules

- Define performance using distributions: median, high percentiles, and context.
- Define reliability as correct behavior despite faults, not absence of faults.
- Define scalability by load parameters and bottlenecks.
- Design for operability, simplicity, and evolvability from the start.

## Workflow

1. List functional requirements separately from nonfunctional requirements.
2. Define load: users, records, request rates, fan-out, data size, and growth.
3. Define latency targets with percentiles and user-facing impact.
4. Identify likely hardware, software, dependency, and human faults.
5. Choose scalability strategy and explain what resource it adds.
6. Add operability checks: observability, rollback, automation, and incident handling.

## Review Checklist

- Are response-time targets percentile-based?
- Are spikes, hot keys, and celebrity-style fan-out considered?
- Is derived data used intentionally to shift cost between reads and writes?
- Is the design understandable enough to operate and change?
- Are human mistakes included in the reliability model?

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

- DDIA 2e Chapter 2: Defining Nonfunctional Requirements, pages 33-63.
- Key sections: performance; reliability and fault tolerance; scalability; maintainability.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
