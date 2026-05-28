---
name: branch-pr
description: >
  PR creation workflow for this repository using GitFlow, branch policy, and conventional commits.
  Trigger: When creating a pull request, opening a PR, or preparing a GitFlow branch for review.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

## When to Use

Use this skill when:
- Creating a pull request for any change
- Preparing a branch for submission
- Helping a contributor open a PR

---

## Critical Rules

1. **Every PR MUST respect GitFlow base rules**
2. **`main` and `develop` only receive reviewed PRs**
3. **Automated checks must pass** before merge is possible
4. **Branch name must match the repo GitFlow policy**

---

## Workflow

```
1. Create the correct GitFlow branch from the correct base
2. Implement changes with conventional commits
3. Run repo validation
4. Open PR against the allowed base branch
5. Wait for automated checks to pass
```

---

## Branch Naming

Branch names MUST match one of these patterns:

```
^feature\/[a-z0-9._-]+$
^release\/v[0-9]+\.[0-9]+\.[0-9]+$
^hotfix\/[a-z0-9._-]+$
```

| Branch type | Base branch | PR target |
|-------------|-------------|-----------|
| `feature/*` | `develop` | `develop` |
| `release/*` | `develop` | `main` |
| `hotfix/*` | `main` | `main` |

Examples:

- `feature/installer-cli`
- `release/v0.2.0`
- `hotfix/fix-opencode-merge`

---

## PR Body Format

The PR template is at `.github/PULL_REQUEST_TEMPLATE.md`. Every PR body MUST contain:

### 1. Summary

1-3 bullet points of what the PR does.

### 2. Changes Table

```markdown
| File | Change |
|------|--------|
| `path/to/file` | What changed |
```

### 3. Test Plan

```markdown
- [x] `./scripts/lint.sh`
- [x] `./scripts/check.sh` (si aplica localmente)
- [x] Manually tested the affected functionality
```

### 4. Contributor Checklist

All boxes must be checked:
- Opened PR against the correct GitFlow base branch
- Branch name matches GitFlow policy
- Ran repo validation
- Skills tested in at least one agent
- Docs updated if behavior changed
- Conventional commit format

---

## Automated Checks (all must pass)

| Check | Job name | What it verifies |
|-------|----------|-----------------|
| Quality | `lint` | Scripts y convenciones del repo |
| PR Branch Policy | `validate` | Branch naming y base permitida por GitFlow |

---

## Conventional Commits

Commit messages MUST match this regex:

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```

**Format:** `type(scope): description` or `type: description`

- `type` — required, one of: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- `(scope)` — optional, lowercase with `a-z0-9._-`
- `!` — optional, indicates breaking change
- `description` — required, starts after `: `

Examples:
```
feat(scripts): add Codex support to setup.sh
fix(skills): correct topic key format in sdd-apply
docs(readme): update multi-model configuration guide
refactor(skills): extract shared persistence logic
chore(ci): add shellcheck to PR validation workflow
perf(scripts): reduce setup.sh execution time
style(skills): fix markdown formatting
test(scripts): add setup.sh integration tests
ci(workflows): add branch name validation
revert: undo broken setup change
feat!: redesign skill loading system
```

---

## Commands

```bash
# Create branch
git checkout develop
git checkout -b feature/my-change

# Validate before pushing
./scripts/lint.sh

# Push and create PR
git push -u origin feature/my-change
gh pr create --base develop --title "feat(scope): description"
```

## Model routing hints

- preferred agent: repo-agent
- preferred model: ollama/devstral:latest
- routing intent: hint only; the skill must not switch models directly
