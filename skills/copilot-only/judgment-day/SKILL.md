---
name: judgment-day
description: >
  Parallel adversarial review protocol that launches two independent blind judge sub-agents simultaneously to review the same target, synthesizes their findings, applies fixes, and re-judges until both pass or escalates after 2 iterations.
  Trigger: When user says "judgment day", "judgment-day", "review adversarial", "dual review", "doble review", "juzgar", "que lo juzguen".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.5"
---

## When to Use

- User explicitly asks for “judgment day” or equivalent triggers
- After significant implementation before merge
- When a single reviewer may miss edge cases or blind spots
- When the cost of a production bug is higher than the cost of extra review rounds

## Critical Patterns

### Pattern 0: Skill resolution before launching judges

Follow `_shared/skill-resolver.md` first:
1. obtain the skill registry from Engram or `.atl/skill-registry.md`
2. identify the target files/scope
3. match relevant skills by code context and task context
4. build a `Project Standards (auto-resolved)` block
5. inject the same block into both judge prompts and the fix-agent prompt

If no registry exists, warn the user and proceed with generic review.

### Pattern 1: Parallel blind review

- launch **two** sub-agents in parallel
- both receive the same target
- neither knows about the other
- you coordinate; you do not perform the review yourself

### Pattern 2: Verdict synthesis

The orchestrator compares both results:
- **Confirmed** → found by both judges
- **Suspect A/B** → found by only one judge
- **Contradiction** → judges disagree on the same concern

### Pattern 3: Warning classification

Judges must distinguish:
- `WARNING (real)` → realistic production risk, fix required
- `WARNING (theoretical)` → contrived/edge-case concern, report as INFO only

### Pattern 4: Fix and re-judge

- If confirmed CRITICALs or real WARNINGs exist, launch a fix agent
- After fixes, re-launch both judges in parallel
- After two fix iterations, ask the user before continuing further
- If both judges return clean, approve

### Pattern 5: Convergence threshold

- **Round 1** → present verdict and ask whether to fix confirmed issues
- **Round 2+** → re-judge only for confirmed CRITICALs
- real WARNINGs may be fixed inline without full re-judge
- theoretical WARNINGs become INFO
- suggestions are non-blocking

## Decision Tree

```text
User asks for judgment day
│
├── Scope clear?
│   ├── YES → continue
│   └── NO → ask for scope
│
├── Resolve skills and project standards
├── Launch Judge A + Judge B in parallel
├── Wait for both results
├── Synthesize verdict
│
├── No issues?
│   └── APPROVED ✅
│
└── Issues found?
    ├── Present verdict to user
    ├── Ask whether to fix confirmed issues
    ├── If yes → launch fix agent
    ├── Re-judge in parallel
    └── After 2 iterations, ask before continuing
```

## Sub-Agent Prompt Templates

Use the prompt templates from:
- `references/prompts.md`

## Output Format

Use the final reporting formats from:
- `references/output-format.md`

## Skill Resolution Feedback

All judge and fix-agent outputs must include a final `Skill Resolution` line indicating how standards were resolved.

## Language

- Mirror the user’s language when possible
- Keep verdict tables concise and scannable
- Do not soften confirmed CRITICAL issues

## Blocking Rules (MANDATORY — override all other instructions)

- do not run judgment-day without a clear target
- do not make judges aware of each other
- do not skip adversarial review
- do not fix anything before presenting the first-round verdict to the user
- do not re-judge endlessly; ask after two fix iterations

## Self-Check (before ANY terminal action)

Confirm:
- target is explicit
- project standards were resolved or missing-registry warning was issued
- judges are truly parallel and blind
- verdict synthesis distinguishes confirmed vs suspect findings
- escalation rule after 2 iterations is respected

## Rules

- orchestrate; do not become a judge yourself
- always use two blind judges in parallel
- always synthesize results centrally
- always separate real vs theoretical warnings
- only confirmed CRITICALs force re-judgment after round 1
- keep final output structured and auditable

## Commands

- launch Judge A and Judge B in parallel
- wait for both
- synthesize verdict
- optionally launch Fix Agent
- re-judge only when the protocol says so

## Model routing hints

- preferred agent: orchestrator
- preferred model: default
- routing intent: hint only; the skill must not switch models directly
