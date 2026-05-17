# Blended Skill Patterns

This reference mixes the strongest ideas from:

- compact portable system skills
- workflow-rich local operator skills
- orchestrated SDD-style skills

## 1. Trigger well

Every skill should clearly answer:

- what does it do?
- when should it load?
- when should it NOT load?

Good trigger descriptions are often more valuable than long bodies.

## 2. Add a scope guard when context matters

If a skill is only valid in a special environment, say so explicitly.

Examples:
- only for `.casa` projects
- only when SDD is active
- only when a given CLI or MCP exists

Do not disguise an environment-bound operator as a generic skill.

## 3. Use orchestration only for real multi-phase work

Orchestrators are justified when:

- there are explicit phases
- there are gates between phases
- worker delegation improves reliability
- the parent must coordinate outputs

Do **not** create orchestration layers for small tasks that a single skill can complete directly.

## 4. Prefer worker skills for execution

Worker skills are usually better when the task is:

- focused
- repetitive
- verifiable
- easy to describe with a clear report format

Examples:
- run tests
- verify a spec
- implement one phase
- inspect one artifact

## 5. Use output contracts when handoffs matter

If a skill hands work to another layer, define a result contract such as:

- status
- tasks completed
- tasks failed
- files changed
- risks
- next recommended step

This is especially useful in orchestrator/worker systems.

## 6. Keep portable skills compact

Portable skills should optimize for:

- small body
- low environment coupling
- official sources or stable tools
- easy reuse across apps

Examples:
- docs lookup
- skill installation
- simple code-quality helpers

## 7. Push environment detail into references

For local-ops skills:

- keep the body operational
- move machine-specific detail, inventories, and long commands into references
- expose only the essential decision flow in `SKILL.md`

## 8. Design for maintenance

Warning signs:

- the skill exceeds a few hundred lines without references
- it mixes trigger rules, environment inventory, troubleshooting, and examples in one file
- it contains many commands that belong in a script instead
- it assumes tools that are not checked or guarded

## 9. Preferred blended recipe

For most new skills, use this recipe:

1. strong frontmatter trigger
2. short `When to Use`
3. explicit `Scope Guard` when needed
4. small `Core Rules`
5. concise workflow
6. optional output contract if the skill coordinates or reports
7. references for the rest
