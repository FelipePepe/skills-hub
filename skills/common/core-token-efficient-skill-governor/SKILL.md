---
name: core-token-efficient-skill-governor
description: Govern creation and refactoring of AI skills using token-efficient practices.
---

# Core Token Efficient Skill Governor

## Purpose

Define baseline rules for creating, auditing, and refactoring skills with low-token, safe, bounded agent behavior.

## Use This Skill When

Use this skill when creating governance, auditing skill instructions, standardizing outputs, or reducing agent token usage.

## Language Policy

- Internal instructions: English.
- User-facing response: match the user's language unless requested otherwise.
- Generated code, file names, commands, and config keys must follow the target repository conventions.

## Core Dependencies

This core skill defines baseline governance rules for other skills. It may omit dependencies that would create circular guidance.

## Workflow

1. Identify whether the task creates, audits, or refactors skills.
2. Keep skills flat under the correct source folder.
3. Require explicit triggers, bounded output, and minimal tools.
4. Apply repository safety rules before editing.
5. Validate with the cheapest relevant command.

## Tool Policy

Allowed tools:
- File read
- File edit
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
Prefer clear code, concise comments, and structured summaries.
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

## Success Criteria

- Skills remain flat direct children of `skills/common`, `skills/copilot-only`, or `skills/claude-only`.
- New or edited skills have bounded outputs and safety policies.
- Validation results are reported concisely.
