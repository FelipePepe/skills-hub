---
name: skill-creator
description: "Create or update reusable AI agent skills: trigger metadata, lean instructions, progressive disclosure. Trigger: create a new skill, improve one, or codify a recurring workflow."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.1"
---

## When to Use

| Create | Skip |
|--------|------|
| Pattern repeated across sessions | One-off task |
| Project conventions differ from defaults | Docs already cover it |
| Complex workflow needs a stable decision tree | Trivial / self-explanatory |

## Archetypes

| Archetype | Best for | Portability |
|-----------|----------|-------------|
| Portable utility | Docs lookup, installers, focused helpers | High |
| Environment-bound | Deployment, local infra, intranet workflows | Low |
| Worker | Testing, review, phase execution | Medium |
| Orchestrator | Multi-phase workflows with sub-agents and gates | Low |

Default: **portable utility**. Use orchestrator only when phases or gates materially improve reliability.

## Workflow

1. Pick archetype and name — lowercase kebab-case (`typescript`, `myapp-api`, `skill-creator`)
2. Write frontmatter first: `name`, `description` (must include trigger wording), `license`, `metadata`
3. `SKILL.md` body: when to use + core rules + minimal workflow + output contract
4. Move verbose material to `references/`; code templates to `assets/`

## Quick Template

```md
---
name: {skill-name}
description: >
  {What it does}. Trigger: {When to load}.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- {condition}

## Scope Guard

- {when NOT to use or environment assumptions}

## Core Rules

- {what the model must not miss}

## Output

{format} — one line per result. No preamble.
```

## Naming

| Type | Pattern | Example |
|------|---------|---------|
| Generic | `{technology}` | `pytest`, `typescript` |
| Project | `{project}-{component}` | `myapp-api` |
| Workflow | `{action}-{target}` | `skill-creator` |

## Checklist

- [ ] Skill does not already exist
- [ ] Name follows conventions; frontmatter `name` matches directory
- [ ] Description includes explicit trigger wording
- [ ] Output contract defined (format + hard limits)
- [ ] Verbose detail moved to `references/`; no duplication of existing docs
- [ ] Archetype choice documented

See `references/validation.md` for full rules.

## Output

```
SKILL:{name} PATH:{path} ARCHETYPE:{portable|env-bound|worker|orchestrator} LINES:{n}
```
No prose. One line only.
