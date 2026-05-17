---
name: skill-creator
description: >
  Create or update reusable AI agent skills with clear trigger metadata, lean
  instructions, and progressive disclosure. Trigger: When the user asks to
  create a new skill, improve an existing one, add agent instructions, or
  codify a recurring workflow for AI.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## When to Use

- Reusable workflow → agent guidance needed
- Project conventions differ from generic best practices
- Complex task needs stable decision tree
- Existing skill too vague, too long, or poorly structured

Do NOT create when: docs exist, pattern trivial, one-off task.

## Core Principles

1. **Be concise** — model is competent; only include what it can't infer
2. **Progressive disclosure** — `SKILL.md` focused, detail in `references/`
3. **Right freedom level** — high (heuristics), medium (common patterns), low (fragile workflows)
4. **References over duplication** — don't copy large docs
5. **Design for triggering** — frontmatter must clearly say what/when
6. **Separate portability from local power** — don't pretend to be generic
7. **Only orchestrate when justified** — multi-agent for SDD-class, not every task

## Skill Archetypes

| Archetype | Best for | Size | Portability |
|---|-|--|-|
| Portable utility | Docs lookup, helpers | Small | High |
| Environment-bound operator | Intranet, deployment | Medium | Low |
| Specialist worker | Testing, review, phase execution | S/M | Medium |
| Orchestrator | Multi-phase with gates | M/L | Low |

**Prefer portable utility.** Use orchestrator only when phases/gates/subagents improve reliability.

## Workflow

1. **Should this be a skill?** — Repeated workflow or project rule → yes. One-off or doc-exists → no.
2. **Name** — lowercase kebab-case: `typescript` (generic), `myapp-api` (project), `skill-creator` (workflow)
3. **Structure** — `skills/{name}/SKILL.md + optional references/ scripts/ assets/`
4. **Frontmatter first** — name, description (what + when), license, metadata (author, version)
5. **Keep SKILL.md lean** — When to Use, Core Rules, Short Workflow, Minimal Commands, References
6. **Split detail to references/** — framework-specific, domain-specific, verbose examples, edge cases

## Quick Template

```md
---
name: {name}
description: >
  {What}. Trigger: {When}.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "1.0"
---
## When to Use — {when}
## Scope Guard — {when not}
## Core Rules — {what must not miss}
## Workflow — {short flow}
## Resources — see references/
```

## Naming

| Type | Pattern | Examples |
|---|-|--|
| Generic | `{tech}` | `pytest`, `typescript` |
| Project | `{project}-{component}` | `myapp-api` |
| Testing | `{project}-test-{component}` | `myapp-test-api` |
| Workflow | `{action}-{target}` | `skill-creator` |

## Checklist

- Skill doesn't already exist
- Pattern reusable
- Name follows conventions
- Frontmatter has clear trigger
- Critical patterns obvious
- Archetype chosen correctly
- Scope guard explicit
- Detail moved to references/
- Scripts/assets only when they help

## Model routing hints

- preferred agent: documenter
- preferred model: ollama/qwen3.6:27b
