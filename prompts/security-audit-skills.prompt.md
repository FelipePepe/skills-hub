# Security Audit Skills

Audit new or modified `skills-hub` skills and prompts for unsafe assistant behavior.

## Scope

Inspect all new or modified files under:

```text
projects/workflow/skills/common
projects/workflow/skills/copilot-only
projects/workflow/skills/claude-only
prompts
```

## Risk Classes

Classify findings as:

- `HIGH`: likely malicious or directly unsafe instruction.
- `MEDIUM`: risky instruction that needs clarification or approval.
- `LOW`: security documentation, forbidden examples, or clearly blocked examples.

## Detect

Look for destructive commands, credential access, exfiltration, remote code execution, privilege escalation, persistence mechanisms, repository compromise, prompt-injection-like behavior, hidden behavior, validation bypasses, and instructions that override repository safety rules.

## Workflow

1. Inspect only relevant changed files.
2. Run the security scanner when available.
3. Identify concrete unsafe wording.
4. Propose safe rewrites that preserve the skill's purpose.
5. Never apply dangerous changes automatically.
6. Keep the report bounded.

## Safety

Do not commit, push, create a PR, delete files, run destructive commands, install packages, or modify app-local target directories. Apply local repository changes only.

## Final Output

```text
SECURITY_RESULT:
- <PASS|WARN|FAIL>

FINDINGS:
- <max 10 findings>

RECOMMENDED_CHANGES:
- <max 5 bullets>

VALIDATION:
- <passed|failed|not run>
```
