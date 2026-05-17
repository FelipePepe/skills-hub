---
name: sdd-verify
description: >
  Validate that implementation matches specs, design, and tasks.
  Trigger: When the orchestrator launches you to verify a completed (or partially completed) change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "3.2"
---

## Harness #12 — Evidence, Not Belief

"It works" is not evidence. Every scenario must be covered by a PASSING test.

## Purpose

Prove with execution evidence that implementation is complete, correct, and spec-compliant. Static analysis alone is NOT enough.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Section B and C.
- `engram` → `sdd/{name}/verify-report`
- `openspec` → `openspec/changes/{name}/verify-report.md`
- `hybrid` → both
- `none` → return inline

## Process

1. **Load skills** — Section A; if React → load `react-doctor`
2. **Resolve TDD mode** from testing capabilities
3. **Check completeness** — compare tasks done vs. total; CRITICAL if core incomplete, WARNING if only cleanup
4. **Check correctness (static)** — for each spec requirement/scenario, find implementation evidence; missing → CRITICAL, partial → WARNING
5. **Check coherence (design)** — verify approach used, rejected alternatives NOT implemented
6. **Run tests** — detect runner (cached capabilities → config.yaml → package.json/go.mod/Makefile)
   - Capture: total/passed/failed/skipped, exit code. Any failure → CRITICAL
7. **Build + type check** — build failure → CRITICAL, type errors → WARNING
8. **Spec compliance matrix** — for each scenario: COMPLIANT | FAILING | UNTESTED | PARTIAL (must have PASSING test)
9. **Adversarial review** (mandatory) — attack vectors, malformed input, concurrency, corruption, injection, wrong assumptions
10. **React doctor** (if React) — render loops, effect deps, derived state, list keys, hydration, component size
11. **Persist report** — topic_key: `sdd/{name}/verify-report` (MANDATORY)
12. **Return summary** — per Section D of `sdd-phase-common.md`

If Strict TDD active → execute extra checks from `strict-tdd-verify.md` (TDD evidence, layer distribution, changed-file coverage, assertion quality).

## Rules

- ALWAYS read actual source code — never trust summaries
- ALWAYS execute tests — static analysis insufficient
- If React → ALWAYS load `react-doctor`
- COMPLIANT only when a covering test PASSES
- Compare against specs first, design second
- CRITICAL blocks archive; WARNINGS should be fixed; SUGGESTIONS non-blocking
- DO NOT fix issues — only report
- Apply any `rules.verify` from `openspec/config.yaml`

## Model routing hints

- preferred agent: tester
- preferred model: ollama/qwen3-coder:30b
