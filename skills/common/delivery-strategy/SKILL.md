---
name: delivery-strategy
description: >
  Delivery Strategy + Chain Strategy harnesses — manages how completed work is
  delivered via PRs: single PR, stacked PRs, or feature-track branching.
  Handles branch creation, PR sequencing, and rollback strategy.
  Trigger: after review-warlock determines a chain is needed, or when the user
  asks how to deliver a large change, "chain PRs", "split PRs", "stacked PRs".
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  version: "1.0"
  harness: agnostic
---

## Harness #19: Delivery Strategy

The geometry of delivery is an engineering decision, not an afterthought.

This harness takes the delivery plan from `review-warlock` and executes it: creates branches, sequences PRs, and manages the chain so that review and merge are controlled and safe.

## Strategy Selection

### Single PR

When: change is small (< 400 lines, single concern, low risk).

```
feature/{change-name} → main
```

Actions:
1. Ensure all tasks are done
2. Run `sdd-verify`
3. Open one PR: `feature/{change-name}` → `main`
4. PR title: conventional commit format (e.g., `feat(auth): add JWT refresh token`)
5. PR body: summary, test plan, risks

### Ask on Risk

When: medium-sized change, risk signals ambiguous.

Proceed normally as Single PR. If during apply a risk signal triggers (unexpected scope growth, design change needed, > 400 lines materializing), pause and invoke `review-warlock` with the updated estimate.

### Harness #20: Chain Strategy

When: `review-warlock` determined a chain is needed.

The chain strategy defines:
- How branches are structured (stacked vs independent)
- Merge order
- Rollback approach

---

## Chain Patterns

### Pattern A — Stack to Main

```
main
  └── feature/{change}/unit-1  ← PR 1 → main
  └── feature/{change}/unit-2  ← PR 2 → main (after unit-1 merges)
  └── feature/{change}/unit-3  ← PR 3 → main (after unit-2 merges)
```

**Use when**: units are independent, team merges fast, startup culture.

**Branch commands**:
```bash
git checkout main && git pull
git checkout -b feature/{change}/unit-1
# implement unit-1 tasks
git checkout -b feature/{change}/unit-2 main
# implement unit-2 tasks
```

**Merge order**: unit-1 → unit-2 → unit-3 (sequentially, each rebased after previous merges).

**Rollback**: revert the specific unit PR. Other units are unaffected if they have not merged.

---

### Pattern B — Feature Track

```
main
  └── feature/{change}/track    ← final merge PR → main
        ├── feature/{change}/unit-1  ← PR 1 → track
        ├── feature/{change}/unit-2  ← PR 2 → track
        └── feature/{change}/unit-3  ← PR 3 → track
```

**Use when**: team wants full-feature review before main, rollback must be surgical.

**Branch commands**:
```bash
git checkout main && git pull
git checkout -b feature/{change}/track  # empty branch, no commits yet
git push -u origin feature/{change}/track

git checkout -b feature/{change}/unit-1 main
# implement unit-1 tasks
# open PR: unit-1 → track

git checkout -b feature/{change}/unit-2 main
# implement unit-2 tasks
# open PR: unit-2 → track
```

**Merge order**: unit PRs → track (any order if independent), then track → main.

**Rollback**: `git revert -m 1 {track-merge-sha}` — reverts entire feature in one operation.

---

### Pattern C — Stacked PRs

```
main
  └── feature/{change}/unit-1     ← PR 1 → main
        └── feature/{change}/unit-2  ← PR 2 → unit-1
              └── feature/{change}/unit-3  ← PR 3 → unit-2
```

**Use when**: units have hard dependencies (unit-2 builds on unit-1's code).

**Branch commands**:
```bash
git checkout main && git pull
git checkout -b feature/{change}/unit-1
# implement unit-1
# open PR: unit-1 → main

git checkout -b feature/{change}/unit-2 feature/{change}/unit-1
# implement unit-2 (which uses unit-1's code)
# open PR: unit-2 → unit-1

git checkout -b feature/{change}/unit-3 feature/{change}/unit-2
# implement unit-3
# open PR: unit-3 → unit-2
```

**After unit-1 merges to main**: rebase unit-2 onto main, rebase unit-3 onto unit-2.

**Rollback**: revert in reverse order (unit-3, unit-2, unit-1).

---

## PR Template

Each PR in a chain should follow this body template:

```markdown
## Summary
{1-3 bullet points of what this PR does}

## Part of Change
Change: `{change-name}` | Unit: `{N}/{total}` | Pattern: `{Stack/Track/Stacked}`
Previous unit: #{PR-number} | Next unit: #{PR-number}

## Tasks Included
- {task 1.1}
- {task 1.2}

## Test Plan
- [ ] Unit tests pass (`{test-command}`)
- [ ] Manual test: {specific scenario to verify}
- [ ] No regression in {area}

## Risk and Rollback
{risk level} — rollback: {specific revert command or strategy}
```

## State per Delivery Unit

Track each unit's status:

```yaml
# openspec/changes/{change-name}/delivery.yaml
strategy: stack_to_main | feature_track | stacked_prs | single_pr
units:
  - id: unit-1
    tasks: [1.1, 1.2, 1.3]
    branch: feature/{change}/unit-1
    pr_number: null
    status: pending | open | merged
  - id: unit-2
    ...
```

Or in Engram: `topic_key: "sdd/{change-name}/delivery"`

## Harness #26: Rollback

Every delivery unit must have a documented rollback path BEFORE the PR is opened.

| Strategy | Rollback |
|---|---|
| Single PR | `git revert -m 1 {merge-sha}` |
| Stack to Main | `git revert -m 1 {unit-merge-sha}` (per unit, reverse order) |
| Feature Track | `git revert -m 1 {track-merge-sha}` (reverts full feature) |
| Stacked PRs | Rebase chain after reverts (complex — document explicitly) |

Include rollback command in every PR description. Never merge without it.

## Rules

- **Every PR must be independently deployable** — no broken intermediate states
- **One logical concern per PR** — never mix concerns for delivery convenience
- **Tests must pass before opening a PR** — not "I'll add tests later"
- **Rollback path is mandatory** — document it in the PR before opening
- **Stack to Main is the simplest pattern** — default to it unless there's a reason to use Track or Stacked
- **Feature Track is best for rollback safety** — use it when one-command rollback matters
- **Stacked PRs are hardest to maintain** — only use when units have genuine hard dependencies
