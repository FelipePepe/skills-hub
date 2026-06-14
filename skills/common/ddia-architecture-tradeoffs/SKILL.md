---
name: ddia-architecture-tradeoffs
description: >
  Review data-system architecture trade-offs across workload shape, deployment model, and operational constraints.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Architecture Tradeoffs

## Purpose

Review data-system architecture trade-offs across workload shape, deployment model, and operational constraints.

## Use This Skill When

- Choosing OLTP, OLAP, HTAP, warehouse, lake, or derived-data architecture.
- Deciding whether to use managed cloud services or self-hosted systems.
- Deciding whether a workload needs distribution or can remain single-node.

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

- Do not recommend distributed systems by default.
- Do not treat cloud services as automatically cheaper, easier, or safer.
- Pair with `ddia-nonfunctional-requirements` when requirements are vague.

## Core Rules

- Separate systems of record from derived data unless the design deliberately combines them.
- Match operational systems to low-latency point reads/writes; match analytical systems to scans, aggregation, and exploration.
- Use distribution for concrete needs: availability, scale, latency, elasticity, legal placement, or specialized hardware.
- Count operational control, vendor lock-in, cost visibility, and debugging access as first-class trade-offs.

## Workflow

1. Classify the workload: operational, analytical, hybrid, or pipeline.
2. Identify systems of record and every derived data copy.
3. Decide whether the workload fits one node before adding distribution.
4. Compare cloud service, self-hosted managed software, and custom implementation.
5. Document who operates each component and how failures are diagnosed.

## Review Checklist

- Is every data copy labeled authoritative or derived?
- Can expensive analytical work harm user-facing operations?
- Are cloud quotas, cost drivers, and vendor lock-in risks visible?
- Is the distribution rationale explicit and measurable?
- Are legal, privacy, and user-rights constraints surfaced?

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

- DDIA 2e Chapter 1: Trade-Offs in Data Systems Architecture, pages 1-31.
- Key sections: operational vs analytical systems; cloud vs self-hosting; distributed vs single-node systems; law and society.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
