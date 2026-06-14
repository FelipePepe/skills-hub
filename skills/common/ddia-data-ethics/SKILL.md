---
name: ddia-data-ethics
description: >
  Review privacy, consent, accountability, fairness, and harm risks in data-intensive or predictive systems.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# Ddia Data Ethics

## Purpose

Review privacy, consent, accountability, fairness, and harm risks in data-intensive or predictive systems.

## Use This Skill When

- Reviewing systems that collect, infer, score, rank, recommend, or decide about people.
- Designing analytics with personal data, tracking, consent, or sensitive attributes.
- Evaluating feedback loops and harms from automated decisions.

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

- This is not legal advice; pair with privacy and compliance review when needed.
- Do not reduce ethics to checklist compliance.
- Pair with `eu-gdpr` when EU personal data may be involved.

## Core Rules

- Predictive systems can amplify historical bias and create unfair exclusion.
- Accountability must remain with people and organizations, not algorithms.
- Feedback loops can reinforce harmful outcomes.
- Privacy is about control, context, and power, not just secrecy.
- Consent must be meaningful, informed, and revocable to be ethically useful.

## Workflow

1. Identify who the data describes and who benefits from processing it.
2. List decisions or recommendations that affect people.
3. Check for protected traits, proxies, and biased historical labels.
4. Evaluate consent, choice, retention, and secondary use.
5. Identify feedback loops and unintended incentives.
6. Define appeal, correction, explanation, and accountability paths.

## Review Checklist

- Can a person contest or correct an automated outcome?
- Are proxy variables recreating prohibited discrimination?
- Is tracking necessary for the user benefit claimed?
- Could the system punish vulnerable groups or amplify inequality?
- Are data retention and reuse bounded by user expectations?

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

- DDIA 2e Chapter 14: Doing the Right Thing, pages 585-601.
- Key sections: predictive analytics; bias; accountability; feedback loops; privacy and tracking; consent; data power.

## Success Criteria

- The response identifies relevant assumptions and trade-offs.
- Recommendations remain operational and bounded.
- No long verbatim DDIA excerpts are included.
