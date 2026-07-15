---
name: sdd-proposal
description: >
  Legacy compatibility alias for the SDD proposal phase.
  Trigger: only when an old prompt, script, or legacy documentation explicitly
  references `sdd-proposal`; use `sdd-propose` for all new flows.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.2"
---

## Status

This skill is a legacy alias.

- **Canonical skill**: `sdd-propose`
- **Use this skill only** if an old prompt, script, or legacy documentation explicitly names it
- **Do not** create new references to `sdd-proposal`

## What to Do

1. Load and follow `projects/workflow/skills/common/sdd-propose/SKILL.md`
2. Preserve name compatibility in the summary if the legacy context requires it
3. Return the result using the format and persistence defined by `sdd-propose`

## Rules

- Treat `sdd-propose` as the source of truth
- Do not diverge in format, persistence, or contract
- If updating documentation, replace `sdd-proposal` with `sdd-propose`

## Output contract

Follow the output contract of `sdd-propose` exactly. No additional prose.
