# Implement Token-Efficient Skills Structure

Implement or update token-efficient skills inside `skills-hub`.

## Rules

- Use `projects/workflow/skills/common` by default.
- Use `projects/workflow/skills/copilot-only` only for Copilot/OpenCode-specific behavior.
- Use `projects/workflow/skills/claude-only` only for Claude-specific behavior.
- Keep every skill as a direct child directory; do not create nested category folders.
- Folder name must match frontmatter `name` exactly.
- Keep each `SKILL.md` under 300 lines; move support material to `references/` when needed.
- Use `pnpm` for JS/TS package-manager examples.
- Do not introduce obsolete naming; use `atlas` / `atlas.casa` where relevant.

## Safety

Do not commit, push, create a PR, delete files, run destructive commands, install packages, or modify app-local target directories. Apply local repository changes only.

## Validation

Prefer cheap validation first:

```bash
git status --short
./scripts/doctor-skills.sh
./scripts/lint.sh
pnpm skills-hub status
```

## Output

Return only changed files, validation status, and at most two notes.
