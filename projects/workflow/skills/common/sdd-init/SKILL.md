---
name: sdd-init
description: "Initialize SDD in a project: detect stack, conventions, testing; bootstrap the real OpenSpec CLI and the skill registry. Trigger: 'sdd init', 'iniciar sdd', 'openspec init'."
license: MIT
metadata:
  author: gentleman-programming
  version: "5.0"
---

## Purpose

You initialize SDD context in a project:
- detect stack and conventions
- detect testing capabilities
- confirm Strict TDD is enforceable
- bootstrap the real OpenSpec CLI

You are an executor for this phase. Do the initialization work yourself.

## Execution Contract

Use:
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

### Step 3: Confirm Strict TDD is enforceable

Strict TDD (red → green → refactor) is ALWAYS `true` — no exception, no config override, no interactive question.

If no test runner exists, this is a blocking gap: report it and recommend adding one before `sdd apply` runs, rather than silently downgrading to non-TDD implementation.

### Step 4: Bootstrap the real OpenSpec CLI

Do NOT hand-write the `openspec/` tree. Use the real CLI (`@fission-ai/openspec`, requires Node ≥20.19):

```bash
pnpm dlx @fission-ai/openspec@latest init --tools all --force
```

`--tools all` installs the `/opsx:*` commands for every supported editor/agent (Claude Code, GitHub Copilot, Cursor, Windsurf, OpenCode, etc.), not just Claude — this repo distributes skills to multiple apps, so init must not assume Claude is the only consumer. This creates `openspec/config.yaml` (schema `spec-driven`) and, for Claude Code specifically, `.claude/skills/openspec-*` + `.claude/commands/opsx/*` (`propose`, `apply`, `archive`, `explore`, `sync`, `update`) — equivalent files are installed for the other detected tools. From this point, `sdd new`/`sdd apply`/`sdd archive` delegate artifact writing to these `/opsx:*` commands.

The CLI's default schema has NO `verify` artifact — `sdd-verify` (this repo's own gate) always runs, real execution, independently of the CLI.

Fork the schema once to add our verify artifact so it's tracked like any other:

```bash
pnpm dlx @fission-ai/openspec@latest schema fork spec-driven sdd-verified
```

Then add to `openspec/schemas/sdd-verified/schema.yaml` a `verify` artifact (`requires: [tasks]`, `generates: verify-report.md`) whose instruction points back to the `sdd-verify` skill contract. Set `schema: sdd-verified` in `config.yaml`.

### Step 5: Generate config

The CLI already created `openspec/config.yaml` with `schema:` + empty `context:`/`rules:`. Fill it in — do not overwrite the file structure, edit the existing keys:
- `context:` — concise detected stack/conventions (Step 1)
- `rules.proposal` — require an architecture/design check before proposing if none exists yet (see `sdd/SKILL.md` gate)
- `rules.apply` — strict TDD is ALWAYS on, no exception; if no test runner exists, this is a blocking gap to report, not a reason to disable it. Summarize the RED→GREEN→TRIANGULATE→REFACTOR cycle from `skills/_shared/strict-tdd.md` into these rules so `/opsx:apply` follows it (the CLI has no built-in TDD concept)
- `rules.verify` — require `code-reviewer`, `judgment-day`, `security-review`, `silent-failure-hunter` using a different LLM model than the one used in `sdd apply`; for web projects, e2e tests via Playwright with a screenshot captured per test
- `rules.archive` — require a GitFlow-compliant commit/PR (`gitflow` skill) and an EU AI Act traceability entry before archiving
- testing capabilities section (Step 2)

Keep context concise.

### Step 6: Build skill registry

Follow the `skill-registry` logic:
- scan user-level and project-level skills
- skip `sdd-*`, `_shared`, `skill-registry`
- deduplicate by name (project-level wins)
- scan project convention files like `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, `copilot-instructions.md`
- always write `.atl/skill-registry.md`

### Step 7: Register in company memory (Engram)

Save one observation so this project is discoverable across the whole company memory, not just locally:

```
mem_save(
  title: "sdd/{project}/init",
  topic_key: "sdd/{project}/init",
  type: "decision",
  project: "{project}",
  content: "{detected stack, TDD status, openspec bootstrapped}"
)
```

If Engram is unavailable, skip this and continue — it never blocks init.

### Step 8: Return

Emit exactly this schema:
```
INIT:{project} TDD:{true|false}
STACK:{tech1,tech2} SKILLS:{n-registered}
NEXT:{sdd new|sdd apply}
```
No headers, no prose outside the schema.

## Rules

- NEVER create placeholder specs
- ALWAYS detect the real stack, do not guess
- NEVER behave like the orchestrator in this phase
- If `openspec/` already exists, report that and let the orchestrator decide updates
- Keep `config.yaml` context concise
- ALWAYS detect and persist testing capabilities
- Strict TDD is never disabled; if no test runner exists, report it as a blocking gap to resolve before `sdd apply`
- Return a structured envelope with `status`, `executive_summary`, `detailed_report` (optional), `artifacts`, `next_recommended`, and `risks`

## Output contract

Respond ONLY in the schema defined in Step 8. No preamble, no explanation,
no markdown headers or bullets outside the schema. If you add anything else, you are wrong.
