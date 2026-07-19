# PR Creation Workflow

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

## Conventional Commits

Commit messages MUST match:

```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```

**Format:** `type(scope): description` — `scope` optional (lowercase `a-z0-9._-`),
`!` marks a breaking change.

Examples:

```
feat(scripts): add Codex support to setup.sh
fix(skills): correct topic key format in sdd-apply
refactor(skills): extract shared persistence logic
feat!: redesign skill loading system
revert: undo broken setup change
```

## PR Body Structure

1. **Summary** — 1-3 bullet points of what the PR does.
2. **Changes table** — `| File | Change |` rows for the touched files.
3. **Test plan** — checked list of validations run (lint, tests, manual checks).
4. **Checklist** — correct GitFlow base, branch name matches policy, validation
   run, docs updated if behavior changed, conventional commit format.

If the repo has `.github/PULL_REQUEST_TEMPLATE.md`, follow it instead.

## Commands

```bash
# Create branch
git checkout develop
git checkout -b feature/my-change

# Push and create PR
git push -u origin feature/my-change
gh pr create --base develop --title "feat(scope): description"
```

Wait for the repo's automated checks to pass before merging.
