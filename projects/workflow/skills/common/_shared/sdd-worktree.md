# SDD Git Worktree Policy

Use worktrees as an optional workspace-isolation layer for SDD tasks. This does not replace `openspec` artifact persistence. It only controls where code changes are made.

## When to use

Use a worktree when:
- implementing a risky or long task without disturbing the caller's current checkout
- applying one task while another task or server is running elsewhere
- comparing alternative implementations
- reviewing/verifying a task branch before integration

Do not use a worktree when:
- the change is documentation-only or trivial
- the repo is not clean enough to branch safely and the user did not approve cleanup/stash
- the task must modify uncommitted work in the current checkout

## Naming

Default pattern:

```text
../{repo-name}.sdd/{change-name}/{task-id-slug}/
branch: sdd/{change-name}/{task-id-slug}
```

Example:

```bash
git worktree add ../devmind.sdd/add-login/1-2-auth-service -b sdd/add-login/1-2-auth-service
```

If the branch already exists, omit `-b` and check it out by name.

## Orchestrator responsibilities

Before launching `/opsx:apply`, the orchestrator decides one of:

| Strategy | Use when | Launch prompt must include |
|----------|----------|----------------------------|
| `inline` | one small task, low risk | current repo path |
| `task-worktree` | isolated task implementation | worktree path, branch, base branch, task IDs |
| `batch-worktree` | small dependent task batch | worktree path, branch, base branch, task IDs |

The orchestrator should record the chosen strategy in `openspec/changes/{change-name}/state.yaml`.

## Executor rules

Inside a worktree, an executor MUST:
- treat the worktree path as the project root
- only edit files inside that worktree, plus the active SDD artifact store
- keep task scope limited to assigned task IDs
- mark tasks complete only after code/tests for that task pass locally
- return branch/worktree path in the phase summary

An executor MUST NOT remove worktrees, merge branches, rebase, or delete task branches unless explicitly asked by the orchestrator/user.

## Verification and integration

`task-worktree` verification can prove the task branch is locally correct, but archive requires an integration verification after task branches are merged or applied to the canonical change branch.

Recommended flow:

```text
sdd apply 1.1 in worktree branch sdd/<change>/1-1
sdd apply 1.2 in worktree branch sdd/<change>/1-2
merge/cherry-pick into canonical change branch
sdd verify on canonical change branch
sdd archive only after verify passes there
```

## Cleanup

After successful integration and archive, the orchestrator may suggest cleanup:

```bash
git worktree remove <path>
git branch -d <branch>
git worktree prune
```

Never run cleanup automatically if there are uncommitted changes.
