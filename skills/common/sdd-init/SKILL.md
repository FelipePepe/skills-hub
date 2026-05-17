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

## Harness #3 — Calibration Before Code

No agent should start a cycle without running this first.

## Purpose

Detect stack, conventions, testing capabilities, resolve Strict TDD, bootstrap persistence.

## Persistence

| Mode | Action |
|---|---|
| `engram` | Persist to Engram only |
| `openspec` | Bootstrap `openspec/` filesystem |
| `hybrid` | Both |
| `none` | Detect + return, no writes |

Follow `skills/_shared/engram-convention.md` and `skills/_shared/openspec-convention.md`.

## Process

1. **Detect stack** — package.json, go.mod, pyproject.toml, CI, linters, test frameworks
2. **Detect testing** — runner + framework + command, test layers (unit/integration/E2E), coverage, quality tools
3. **Resolve Strict TDD** — config marker → config.yaml → true if runner exists → false if not
4. **Initialize openspec** (if mode includes filesystem) — create dirs: `openspec/{config.yaml,specs/,changes/archive/}`
5. **Generate config.yaml** — detected context, strict_tdd, phase rules, testing capabilities
6. **Persist testing capabilities** (MANDATORY) — topic_key: `sdd/{project}/testing-capabilities`, type: `config`
7. **Build skill registry** — scan skills, skip `sdd-*`/`_shared`/`skill-registry`, deduplicate (project wins), scan convention files, write `.atl/skill-registry.md` + Engram
8. **Persist project context** (MANDATORY) — topic_key: `sdd-init/{project}`, type: `architecture`
9. **Return structured summary**

## Rules

- NEVER create placeholder specs
- ALWAYS detect the real stack
- NEVER act as orchestrator in this phase
- If `openspec/` exists → report, don't overwrite
- Keep config.yaml context concise
- If Strict TDD requested but no runner → disable + explain

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
