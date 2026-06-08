# Audit Existing Skills

Audit the `skills-hub` catalog for structure, safety, and token efficiency.

## Scope

Inspect likely catalog sources only:

```text
skills/common
skills/copilot-only
skills/claude-only
agents
prompts
opencode
```

## Checks

- Direct child skill directories only.
- Folder name matches frontmatter `name`.
- Every skill has `SKILL.md` under 300 lines.
- Shared skills default to `skills/common`.
- Platform-specific skills stay in `skills/copilot-only` or `skills/claude-only`.
- Outputs are bounded and explanations are disabled by default.
- Tool exposure is minimal.
- `pnpm` is used for JS/TS package-manager examples.
- No obsolete naming is introduced.

## Safety

Do not refactor unrelated skills unless explicitly requested. Do not commit, push, create a PR, delete files, run destructive commands, install packages, or modify app-local target directories.

## Output

Classify findings as:

```text
PASS
WARN
FAIL
```

Return only changed files, validation status, and at most two notes.
