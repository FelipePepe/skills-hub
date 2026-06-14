---
name: core-repository-safety-rules
description: Apply local-only repository safety rules for skills-hub work.
---

# Core Repository Safety Rules

## Purpose

Protect the canonical catalog, user work, and copy-based installation model while changing skills-hub.

## Use This Skill When

Use this skill before edits, synchronization changes, app target changes, or any command with side effects.

## Language Policy

- Internal instructions: English.
- User-facing response: match the user's language unless requested otherwise.
- Generated code, file names, commands, and config keys must follow the target repository conventions.

## Core Dependencies

This core skill defines baseline governance rules for other skills. It may omit dependencies that would create circular guidance.

## Workflow

1. Run `git status --short` when cheap.
2. Confirm edits stay inside the repository workspace.
3. Avoid app-local target directories and install destinations.
4. Preserve copy-based installation and flat skill layout.
5. Stop before destructive, network, package, commit, push, or PR actions unless explicitly requested.

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

- User work is preserved.
- No app-local targets are modified.
- No destructive, installation, commit, push, or PR operation runs without explicit request.
