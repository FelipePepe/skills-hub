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

Use this skill when:
- A reusable workflow should become agent guidance
- Project conventions differ from generic best practices
- A complex task needs a stable decision tree or sequence
- An existing skill is too vague, too long, or poorly structured

Create a new skill when:
- A pattern is used repeatedly and AI needs guidance
- Project-specific conventions differ from generic best practices
- Complex workflows need step-by-step instructions
- Decision trees help AI choose the right approach

Do **not** create a skill when:
- Documentation already exists and a reference is enough
- The pattern is trivial or self-explanatory
- It is a one-off task

## Core Principles

1. **Be concise.** Assume the model is already competent; only include what it would not reliably infer.
2. **Use progressive disclosure.** Keep `SKILL.md` focused, move detail into `references/`, and use scripts/assets only when they add real value.
3. **Choose the right level of freedom.**
   - high freedom for heuristics
   - medium freedom for common patterns
   - low freedom for fragile, exact workflows
4. **Prefer references over duplication.** Do not copy large docs into the body.
5. **Design for triggering.** Frontmatter must clearly say what the skill does and when it should load.
6. **Separate portability from local power.** A skill can be environment-rich, but it should say so explicitly instead of pretending to be generic.
7. **Only orchestrate when justified.** Multi-agent or multi-phase orchestration is useful for SDD-class workflows, not for every small task.

## Skill Archetypes

Choose the archetype before writing:

| Archetype | Best for | Typical size | Portability |
|-----------|----------|--------------|-------------|
| Portable utility | Docs lookup, installers, focused helpers | Small | High |
| Environment-bound operator | Intranet, deployment, local infra workflows | Medium | Low |
| Specialist worker | Testing, verification, code review, phase execution | Small/Medium | Medium |
| Orchestrator | Multi-phase workflows with gates and delegation | Medium/Large | Low |

Rules:
- Prefer **portable utility** by default
- Use **environment-bound operator** only when machine/project context is essential
- Use **orchestrator** only when phases, gates, or subagents materially improve reliability
- If you create an orchestrator, define the workers it coordinates and the result it expects back

## Recommended Workflow

### 1) Decide whether this should be a skill

- Repeated workflow? likely yes
- Project-specific rules? likely yes
- One-off explanation? probably no
- Existing local documentation already covers it? use a reference instead

### 2) Choose a name

Follow lowercase kebab-case naming:

- generic: `typescript`, `pytest`
- project-specific: `myapp-api`
- workflow: `skill-creator`, `jira-task`

### 3) Create the minimum viable structure

```text
skills/{skill-name}/
├── SKILL.md
├── references/   # optional
├── scripts/      # optional
└── assets/       # optional
```

### 4) Write the frontmatter first

Every skill needs:
- `name`
- `description`
- `license`
- `metadata.author`
- `metadata.version`

The description should include both:
- what the skill does
- when it should trigger

### 5) Keep `SKILL.md` lean

A good body usually contains:
- When to use
- Core rules or critical patterns
- Small workflow or decision tree
- Minimal commands/examples
- References to extra material

### 6) Split detail into references

Move long material out when it becomes:
- framework-specific
- domain-specific
- verbose examples
- advanced edge-case guidance

See:
- `references/structure.md`
- `references/progressive-disclosure.md`
- `references/validation.md`
- `references/blended-patterns.md`

## Quick Template

```md
---
name: {skill-name}
description: >
  {What the skill does}. Trigger: {When the AI should load this skill}.
license: Apache-2.0
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "1.0"
---

## When to Use

- {When to use it}

## Scope Guard

- {When NOT to use it}
- {Environment or platform assumptions}

## Core Rules

- {What the model must not miss}

## Workflow

- {Short numbered flow}

## Resources

- See [references/](references/) for detailed guidance
```

## Naming Conventions

| Type | Pattern | Examples |
|------|---------|----------|
| Generic skill | `{technology}` | `pytest`, `playwright`, `typescript` |
| Project-specific | `{project}-{component}` | `myapp-api`, `myapp-ui` |
| Testing skill | `{project}-test-{component}` | `myapp-test-sdk`, `myapp-test-api` |
| Workflow skill | `{action}-{target}` | `skill-creator`, `jira-task` |

## Decision: assets/ vs references/

```text
Need code templates?   → assets/
Need schemas/examples? → assets/
Need detailed docs?    → references/
Need variant guidance? → references/
```

## Content Guidelines

### DO
- Start with the most critical patterns
- Use tables for decision trees
- Keep examples minimal and focused
- Include commands only when they genuinely help execution

### DON'T
- Add filler sections with no triggering value
- Duplicate large docs instead of linking references
- Turn the skill into a README or changelog
- Add long troubleshooting appendices to the main body

## Checklist Before Creating

- [ ] Skill does not already exist
- [ ] Pattern is reusable
- [ ] Name follows conventions
- [ ] Frontmatter includes clear trigger wording
- [ ] Critical patterns are obvious
- [ ] Archetype chosen correctly (portable / environment-bound / worker / orchestrator)
- [ ] Scope guard is explicit when the skill is environment-specific
- [ ] Detailed material moved to `references/` when needed
- [ ] Scripts/assets only added when they materially help

## Resources

- `references/structure.md`
- `references/progressive-disclosure.md`
- `references/validation.md`
- `references/blended-patterns.md`

## Model routing hints

- preferred agent: documenter
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
