---
name: core-token-efficient-command-output
description: Reduce terminal output for agent workflows with concise commands and bounded captures.
---

# Core Token Efficient Command Output

## Purpose

Keep command usage cheap by preferring concise, targeted commands and avoiding noisy terminal output.

## Use This Skill When

Use this skill before running repository commands, diagnostics, validation, searches, or test commands that may produce verbose output.

## Language Policy

- Internal instructions: English.
- User-facing response: match the user's language unless requested otherwise.
- Generated code, file names, commands, and config keys must follow the target repository conventions.

## Core Dependencies

This core skill defines baseline governance rules for other skills. It may omit dependencies that would create circular guidance.

## Workflow

1. Choose the cheapest command that answers the question.
2. Prefer summaries, counts, status lines, and capped output.
3. Use `git status --short` and targeted file reads before broad scans.
4. Run expensive or environment-dependent commands only when needed.
5. Report only the relevant result.

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

## Repository Command Preferences

Prefer:

```bash
git status --short
pnpm skills-hub status
pnpm skills-hub doctor
pnpm skills-hub doctor-skills
pnpm skills-hub lint
pnpm skills-hub check
./scripts/doctor-skills.sh
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

## Success Criteria

- Commands produce bounded output.
- Validation uses repository-preferred commands.
- No full logs or large file dumps are returned unless requested.
