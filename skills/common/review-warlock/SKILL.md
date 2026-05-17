---
name: review-warlock
description: >
  Review Warlock harness — evaluates PR size and risk before delivery, decides
  whether to split into chained PRs, and recommends a delivery strategy.
  Trigger: before opening a PR, after sdd-tasks, when a change exceeds 400 lines
  or touches 3+ independent areas, or when the orchestrator detects high review risk.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  version: "1.0"
  harness: agnostic
---

## Harness #18: Review Warlock

A PR of 1000 lines is not productivity. It is a review debt that someone else pays.

This harness evaluates change size and risk BEFORE delivery. It exists because:
- An unreadable PR rarely gets a real review — it gets rubber-stamped or ignored
- AI-generated code produces "AI slop" PRs — large, untraceable, hard to follow
- Splitting after the fact is painful. Splitting at task-design time is free.

**When to invoke**: after `sdd-tasks`, before `sdd-apply`, or when the orchestrator detects that a change will be large.

## Step 1: Estimate Size and Risk

Analyze the tasks list and design decisions to estimate:

| Signal | Threshold | Risk |
|---|---|---|
| Lines of code changed | > 400 | Moderate |
| Independent areas touched | ≥ 3 | High |
| Files modified | > 10 | Moderate |
| Database migrations included | any | High |
| Public API changes | any | High |
| Multiple logical concerns in one change | any | High |

If **zero** risk signals: recommend **Single PR** strategy. Stop here.

## Step 2: Choose Delivery Strategy

Present the user with options:

### A — Single PR
- Use when: small scope, single concern, < 400 lines
- Risk: low
- Action: proceed directly to `sdd-apply`

### B — Ask on Risk
- Use when: change is medium-sized but risk signals are ambiguous
- Behavior: proceed normally; if a signal is triggered during apply, pause and ask
- Action: set `delivery_strategy = ask_on_risk` in state

### C — Auto-Chain
- Use when: change is clearly large, multiple independent areas
- Behavior: automatically split tasks into PR units and chain them
- Action: go to Step 3

### D — Exception (justified large PR)
- Use when: the change cannot be sensibly split (e.g., a full migration)
- Requires: explicit justification from the user
- Action: document the exception and proceed as Single PR

## Step 3: Design the Chain (if Auto-Chain or requested)

Split tasks into independent delivery units. Each unit must:
- Be independently deployable (no broken intermediate states)
- Have a clear single concern
- Be reviewable in under 30 minutes
- Have its own tests

**Chain patterns:**

### Stack to Main
```
feature/unit-1 → main (PR 1)
feature/unit-2 → main (PR 2, depends on 1 being merged)
```
Use for: startups, high-trust teams with fast release cadence.

### Feature Track
```
feature/unit-1 → feature/track (PR 1)
feature/unit-2 → feature/track (PR 2)
...
feature/track  → main (final merge PR)
```
Use for: larger teams, when you want a rollback point for the full feature.
On rollback: revert only the feature/track merge — clean and contained.

### Stacked PRs (recommended for ordered dependencies)
```
Branch A ← Branch B ← Branch C
PR A: A → main
PR B: B → A (stacked, rebases when A merges)
PR C: C → B (stacked, rebases when B merges)
```
Use for: when each unit builds on the previous one.

## Step 4: Output

Return a delivery plan:

```markdown
## Review Warlock — Delivery Plan

**Change**: {change-name}
**Risk Level**: Low | Moderate | High
**Strategy**: Single PR | Ask on Risk | Auto-Chain | Exception

### Risk Signals Found
- {signal 1}: {detail}
- {signal 2}: {detail}

### Delivery Units (if chained)

#### Unit 1: {name}
- Tasks: {task-ids}
- Files: {affected files}
- PR title: "{suggested title}"
- Branch: `feature/{change-name}/unit-1`
- Base: `main` | `feature/{track}`
- Estimated size: ~{N} lines

#### Unit 2: {name}
...

### Chain Pattern: {Stack to Main | Feature Track | Stacked PRs}

### Suggested PR Order
1. {unit-1 description}
2. {unit-2 description}
```

## Rules

- **Never deliver a PR > 400 lines without justification** — ask the user to split or provide the exception reason
- **One logical concern per PR** — mixed concerns make reviews impossible
- **Each PR must have passing tests** — no "I'll add tests in the next PR"
- **Exception requires explicit user confirmation** — do not silently skip splitting
- **Recommend splitting at task-design time** — splitting during apply is painful
- **The delivery plan is an artifact** — persist it if the persistence mode is not `none`

## Integration with SDD

The orchestrator calls this harness after `sdd-tasks` and before `sdd-apply`:

```
sdd-tasks → review-warlock → [split if needed] → sdd-apply (per unit)
```

If a chain is designed, `sdd-apply` runs once per delivery unit with the relevant task subset.
