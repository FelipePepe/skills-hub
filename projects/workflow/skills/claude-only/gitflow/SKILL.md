---
name: gitflow
description: "Apply GitFlow (feature/* -> develop -> release -> main): branch checks, commits, merges, tags, lefthook, PR creation. Trigger: commit, merge, release, hooks, creating a pull request, 'which branch', 'am I following gitflow?'."
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.3"
---

## When to Use

- The user wants to commit, merge, publish, or tag a version.
- Creating a pull request or preparing a branch for review.
- Asks which branch to use or whether the repo follows GitFlow.
- There are changes or commits on the wrong branch.
- Wants to configure or verify lefthook.

## Quick Protocol

1. Diagnose before touching anything:

```bash
git branch --show-current
git status --short
git log --oneline -5
git branch -a | grep -E "main|develop|feature|release|hotfix"
```

2. Apply the branch model:

```text
main      ← releases/hotfixes only, never direct commits
develop   ← integration
feature/* ← branches from develop, merges back to develop
release/* ← branches from develop, merges to main and develop
hotfix/*  ← branches from main, merges to main and develop
```

3. Starting new work:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/<kebab-case-name>
```

4. Conventional commit:

```text
<type>(<scope>): <imperative description in lowercase, no trailing period>
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `chore`, `ci`, `revert`.

5. For release/hotfix or lefthook, load the full protocol.

## Detailed Reference

For complete release/hotfix commands, commit rules, `lefthook.yml`, hooks, and troubleshooting, load:

- `references/full-protocol.md`

For PR creation (branch naming patterns, conventional commit regex, PR body structure, `gh pr create`), load:

- `references/pr-workflow.md`

## Rules

- ONLY use `pnpm` — never `npm` or `npx`. Use `pnpm dlx` instead of `npx`.
- Never commit directly to `main` or `develop`.
- If `develop` is missing, propose creating it from `main` before continuing.
- If there are uncommitted changes, do not switch branches without protecting them first.
- If you detect a GitFlow violation, explain the risk and propose the minimal fix.
- Do not skip hooks unless the user explicitly justifies it.
