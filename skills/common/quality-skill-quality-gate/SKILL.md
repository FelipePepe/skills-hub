---
name: quality-skill-quality-gate
description: Validate skills against structure, safety, and token-efficiency quality gates.
---

# Quality Skill Quality Gate

## Purpose

Classify new or modified skills against the repository's structural, safety, and token-efficiency requirements.

## Use This Skill When

Use this skill before finishing any skill creation, audit, refactor, or catalog governance change.

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

## Workflow

1. Inspect the skill folder and `SKILL.md` only.
2. Check folder/frontmatter alignment and required sections.
3. Verify safety, tool, output, and token-efficiency rules.
4. Confirm line count stays below 300.
5. Classify the result as PASS, WARN, or FAIL.

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

## Quality Gate Checklist

Classify each skill as `PASS`, `WARN`, or `FAIL`.

```text
[ ] Folder name matches frontmatter name
[ ] Description is short
[ ] Has clear purpose
[ ] Has explicit trigger section
[ ] Has language policy
[ ] Has bounded workflow
[ ] Has tool policy
[ ] Has safety policy
[ ] Has output format
[ ] Has explanation policy
[ ] Has token efficiency rules
[ ] Has success criteria
[ ] Keeps SKILL.md under 300 lines
[ ] Avoids broad context loading
[ ] Avoids unnecessary tools
[ ] Avoids long explanations by default
[ ] Avoids destructive actions by default
[ ] Uses pnpm where JS/TS package manager examples are needed
[ ] Does not introduce obsolete `mente` naming
```

`PASS` means all required checks pass. `WARN` means the skill works but should be improved. `FAIL` means structural, safety, naming, or validation rules are broken.


## Success Criteria

- Every checked skill has a PASS, WARN, or FAIL classification.
- Any FAIL includes a minimal remediation.
- The final report remains bounded.
