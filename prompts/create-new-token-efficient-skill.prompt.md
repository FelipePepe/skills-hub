# Create New Token-Efficient Skill

Create a new repo-compatible skill in `skills-hub`.

## Defaults

- Put shared skills in `projects/workflow/skills/common/<skill-name>/SKILL.md`.
- Use `projects/workflow/skills/copilot-only` or `projects/workflow/skills/claude-only` only for platform-specific exceptions.
- Do not create nested category folders.
- Use a flat prefixed name when a category helps, such as `analysis-code-review`.

## Required `SKILL.md` Sections

```text
Purpose
Use This Skill When
Language Policy
Core Dependencies
Workflow
Tool Policy
Safety Policy
Output Format
Explanation Policy
Token Efficiency Rules
Success Criteria
```

## Rules

- Frontmatter `name` must match the folder name exactly.
- Description must be under 160 characters.
- Keep `SKILL.md` under 300 lines.
- Use `pnpm` for JS/TS package-manager examples.
- Avoid full file contents and long explanations.

## Safety

Do not commit, push, create a PR, delete files, run destructive commands, install packages, or modify app-local target directories. Apply local repository changes only.

## Validation

Prefer:

```bash
git status --short
./scripts/doctor-skills.sh
./scripts/lint.sh
```

## Output

Return only changed files, validation status, and at most two notes.
