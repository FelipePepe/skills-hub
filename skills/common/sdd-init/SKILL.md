---
name: sdd-init
description: >
  Initialize Spec-Driven Development context in any project. Detects stack, conventions, testing capabilities, and bootstraps the active persistence backend.
  Trigger: When user wants to initialize SDD in a project, or says "sdd init", "iniciar sdd", "openspec init".
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "3.1"
---

## Harness #3: SDD Init — Calibration Before Code

An agent that starts implementing without knowing where it stands is like a surgeon entering the operating room without knowing which organ to touch. This skill is the calibration step. No agent should start a cycle without running it first.

## Purpose

You initialize SDD context in a project:
- detect stack and conventions
- detect testing capabilities
- resolve Strict TDD mode
- bootstrap the active persistence backend

You are an executor for this phase. Do the initialization work yourself.

## Execution and Persistence Contract

Mode behavior:
- **engram** → do not create `openspec/`; persist project context and capabilities to Engram
- **openspec** → bootstrap filesystem under `openspec/`
- **hybrid** → do both
- **none** → detect and return, but do not write files

Use:
- `skills/_shared/engram-convention.md`
- `skills/_shared/openspec-convention.md`

## What to Do

### Step 1: Detect project context

Read the project and identify:
- tech stack (`package.json`, `go.mod`, `pyproject.toml`, etc.)
- existing conventions (linters, test frameworks, CI)
- architecture patterns already in use

### Step 2: Detect testing capabilities

Detect all testing infrastructure:
- **test runner** → framework + command
- **test layers** → unit / integration / E2E
- **coverage** → command if available
- **quality tools** → linter, type checker, formatter

Detection sources include:
- `package.json`
- `pyproject.toml`, `pytest.ini`, `setup.cfg`
- `go.mod`, `Cargo.toml`
- `Makefile`
- dependency manifests and scripts

Persist results using the format in:
- `references/testing-capabilities-template.md`

### Step 3: Resolve Strict TDD Mode

Priority order:
1. system prompt / agent config marker
2. `openspec/config.yaml`
3. default to `true` if a test runner exists
4. force `false` if no test runner exists

Do not ask the user interactively.

### Step 4: Initialize persistence backend

If mode includes `openspec`, create:

```text
openspec/
├── config.yaml
├── specs/
└── changes/
    └── archive/
```

### Step 5: Generate config (openspec mode)

Create `openspec/config.yaml` with:
- concise detected context
- `strict_tdd`
- phase rules for proposal/specs/design/tasks/apply/verify/archive
- testing capabilities section when mode includes filesystem persistence

Keep context concise.

### Step 6: Persist testing capabilities

Mandatory.

If mode includes Engram, save a separate observation:
- title: `sdd/{project-name}/testing-capabilities`
- topic_key: `sdd/{project-name}/testing-capabilities`
- type: `config`

If mode includes openspec, also include testing capabilities in `openspec/config.yaml`.

Use the exact structure from:
- `references/testing-capabilities-template.md`

### Step 7: Build skill registry

Follow the `skill-registry` logic:
- scan user-level and project-level skills
- skip `sdd-*`, `_shared`, `skill-registry`
- deduplicate by name (project-level wins)
- scan project convention files like `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, `copilot-instructions.md`
- always write `.atl/skill-registry.md`
- if Engram is available, also persist it there

### Step 8: Persist project context

Mandatory.

If mode includes Engram, save:
- title: `sdd-init/{project-name}`
- topic_key: `sdd-init/{project-name}`
- type: `architecture`

If mode includes openspec, the generated config already captures the filesystem side.

### Step 9: Return summary

Return a structured summary adapted to the resolved mode.
Use the templates from:
- `references/return-modes.md`

## Rules

- NEVER create placeholder specs
- ALWAYS detect the real stack, do not guess
- NEVER behave like the orchestrator in this phase
- If `openspec/` already exists, report that and let the orchestrator decide updates
- Keep `config.yaml` context concise
- ALWAYS detect and persist testing capabilities
- If Strict TDD is requested but no test runner exists, disable it and explain why
- Return a structured envelope with `status`, `executive_summary`, `detailed_report` (optional), `artifacts`, `next_recommended`, and `risks`

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
