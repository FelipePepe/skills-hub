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

## Harness #19 — Delivery Geometry

The geometry of delivery is an engineering decision, not an afterthought.

## Strategies

### Single PR
Change < 400 lines, single concern, low risk. `feature/{name}` → main.

### Ask on Risk
Medium change, ambiguous signals. If risk triggers during apply (scope growth, design change, > 400 lines) → pause, invoke `review-warlock`.

### Harness #20 — Chain Strategy

| Pattern | Structure | Use when |
|---|-|--------|-
| **Stack to Main** | All units → main (sequential) | Independent units, fast merges |
| **Feature Track** | Units → track → main | Full-feature review, surgical rollback |
| **Stacked PRs** | unit-1 ← unit-2 ← unit-3 | Units have hard dependencies |

## PR Template

```markdown
## Summary
{1-3 bullets}

## Part of Change
Change: `{name}` | Unit: `{N}/{total}` | Pattern: `{Stack/Track/Stacked}`

## Tasks
- {task 1.1}

## Test Plan
- [ ] Tests pass (`{command}`)
- [ ] Manual: {scenario}

## Risk and Rollback
{level} — rollback: {command}
```

## State

Track per unit: `openspec/changes/{name}/delivery.yaml` or Engram topic_key: `sdd/{name}/delivery`

## Harness #26 — Rollback

| Strategy | Rollback |
|---|---|
| Single PR | `git revert -m 1 {merge-sha}` |
| Stack to Main | `git revert -m 1 {unit-sha}` (reverse order) |
| Feature Track | `git revert -m 1 {track-sha}` (full feature) |
| Stacked PRs | Rebase chain after reverts |

**Rollback command mandatory in every PR.** Never merge without it.

## Rules

- Every PR independently deployable
- One logical concern per PR
- Tests pass before opening PR
- Rollback documented before opening
- Stack to Main = simplest, default unless other reason
- Feature Track = best for rollback safety
- Stacked PRs = hardest to maintain, use only for genuine dependencies
