# Skill Structure Reference

## Minimal structure

```text
skill-name/
├── SKILL.md
├── references/
├── scripts/
└── assets/
```

Only `SKILL.md` is required.

## What goes where

### `SKILL.md`
- trigger metadata
- short workflow
- critical patterns
- links to deeper material

### `references/`
- detailed docs
- variant-specific guidance
- domain notes
- larger examples

### `scripts/`
- deterministic helpers
- repeated automation
- fragile or exact procedures

### `assets/`
- templates
- schemas
- boilerplate
- files used in outputs

## What not to add

- README.md
- installation guides
- changelogs
- extra process docs that are not needed by the agent
