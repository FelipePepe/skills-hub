---
name: gitflow-casa
description: >
  Applies GitFlow correctly in any repository: feature/* → develop →
  release → main. Reviews branch/state, detects violations, guides commits,
  merges, tags and lefthook. Trigger: commit, merge, release, hooks,
  "which branch", "how do I push this", "am I following GitFlow?".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.3"
---

## When to Use

- The user wants to commit, merge, publish, or tag a version.
- They ask which branch to use or whether the repo follows GitFlow.
- There are changes or commits on incorrect branches.
- They want to configure or verify lefthook.

## Quick Protocol

1. Diagnose before touching anything:

```bash
git branch --show-current
git status --short
git log --oneline -5
git branch -a | grep -E "main|develop|feature|release|hotfix"
```

2. Apply the model:

```text
main      ← releases/hotfixes only, no direct commits
develop   ← integration
feature/* ← branches from develop, merges back to develop
release/* ← branches from develop, merges to main and develop
hotfix/*  ← branches from main, merges to main and develop
```

3. To start new work:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/<kebab-case-name>
```

4. Conventional commit format:

```text
<type>(<scope>): <imperative description in lowercase, no period>
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `chore`, `ci`, `revert`.

5. For release/hotfix or lefthook details, read the full protocol.

## Detailed Reference

For complete release/hotfix commands, commit rules, `lefthook.yml`, hooks and troubleshooting, load:

- `references/full-protocol.md`

## Rules

- Never commit directly to `main` or `develop`.
- If `develop` is missing, propose creating it from `main` before proceeding.
- If there are uncommitted changes, do not switch branches without protecting them first.
- If you detect a GitFlow violation, explain the risk and propose the minimum fix.
- Do not skip hooks without explicit user justification.

## Output contract

```
BRANCH:{name} ACTION:{committed|merged|tagged|created} STATUS:{ok|warn:{message}}
```
One line. If a violation is found: `VIOLATION:{description} FIX:{what to do}`.
