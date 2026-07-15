---
name: sdd-verify
description: >
  Validate that implementation matches specs, design, and tasks.
  Trigger: When the orchestrator launches you to verify a completed (or partially completed) change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.2"
---

## Purpose

You are the verification quality gate. Your job is to prove — with execution evidence — that implementation is complete, correct, and behaviorally compliant with the specs.

Static analysis alone is NOT enough. You must execute the code.

## What You Receive

From the orchestrator:
- change name
- artifact store mode (`engram | openspec | hybrid | none`)

## Execution and Persistence Contract

Follow:
- **Section B** (retrieval) and **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`
- `openspec` conventions from `skills/_shared/openspec-convention.md` when mode requires it

Persistence targets:
- **engram** → save `sdd/{change-name}/verify-report`
- **openspec** → write `openspec/changes/{change-name}/verify-report.md`
- **hybrid** → do both
- **none** → return inline only

## What to Do

### Step 1: Load Skills
Follow **Section A** from `skills/_shared/sdd-phase-common.md`.

If the project is React (for example `react`, `next`, `vite` + React, or React Native is clearly present):
- load `projects/workflow/skills/common/react-doctor/SKILL.md`
- apply its diagnostic checklist during verification
- include its findings in the verification report

### Step 2: Resolve TDD mode from testing capabilities

Read cached testing capabilities and decide:
- if `strict_tdd: true` **and** a test runner exists → load `strict-tdd-verify.md`
- otherwise use standard verification only

Read sources in this order:
- engram → `sdd/{change-name}/testing-capabilities`
- openspec → `openspec/config.yaml`
- fallback → inspect project files directly

### Step 3: Check completeness

Read `tasks` and verify:
- total tasks
- completed tasks
- incomplete tasks

Flag:
- **CRITICAL** if core tasks are incomplete
- **WARNING** if only cleanup tasks are incomplete

### Step 4: Check correctness (static)

For each requirement and scenario in specs:
- find structural implementation evidence in code
- confirm the given/when/then path exists
- flag missing requirements as **CRITICAL**
- flag partial scenarios as **WARNING**

### Step 5: Check coherence (design)

For each design decision:
- verify the chosen approach was used
- verify rejected alternatives were not accidentally implemented
- compare file changes with the design's file-change table

Flag deviations as **WARNING** unless they clearly break the design intent.

### Step 6: Check testing with real execution

#### 6a — Static test analysis
Confirm tests exist for:
- happy paths
- edge cases
- error states
- each important spec scenario

#### 6b — Run tests
Detect and execute the project test command from:
- cached capabilities
- `openspec/config.yaml` overrides
- `package.json`, `pyproject.toml`, `go.mod`, `Makefile`

Capture:
- total / passed / failed / skipped
- failed test names and errors
- exit code

Any failed test is **CRITICAL**.

#### 6c — Build and type check
Detect and execute build/type-check commands using cached capabilities first.

Flag:
- build failure → **CRITICAL**
- type errors with otherwise passing build → **WARNING**

#### 6d — Coverage
If coverage is available:
- run it
- compare against configured threshold if any
- if Strict TDD is active, also apply the expanded changed-file checks from `strict-tdd-verify.md`

If not available, report it cleanly.

### Step 7: Spec compliance matrix

For each spec scenario:
- find the test(s) that cover it
- look up the real result from Step 6
- classify as:
  - ✅ COMPLIANT
  - ❌ FAILING
  - ❌ UNTESTED
  - ⚠️ PARTIAL

A scenario is only COMPLIANT if a real test passed proving the behavior at runtime.

### Step 7a: Strict TDD additions

If Strict TDD is active, execute the extra checks from:
- `strict-tdd-verify.md`
- `references/strict-tdd-tables.md`

These include:
- TDD evidence validation from apply-progress
- test layer distribution
- changed-file coverage detail
- assertion quality audit
- quality metrics for changed files

### Step 7b: Adversarial review

Mandatory red-team review:
- attack vectors
- malformed input
- concurrency and failure modes
- data corruption risks
- privilege escalation / injection risks
- wrong or incomplete assumptions in specs

Classify findings as:
- **CRITICAL**
- **WARNING (real)**
- **WARNING (theoretical)** → report as INFO
- **SUGGESTION**

### Step 7c: React doctor review

If the project is React:
- run the `react-doctor` review against changed React components, hooks, and related UI state flows
- check for render loops, invalid effect dependencies, redundant derived state, unstable list keys, needless memoization, hydration risks, and oversized components
- classify `react-doctor` findings using the same severity model as this verify phase
- treat real React correctness or runtime risks as verification failures until they are corrected in apply

### Step 8: Persist verification report

Persist artifact `verify-report` using the mode rules above.
Use topic key `sdd/{change-name}/verify-report` when Engram applies.

### Step 9: Return

Emit exactly this schema:
```
RESULT:{pass|fail} CRITICALS:{n} WARNINGS:{n}
TESTS:{passed}/{total} BUILD:{ok|fail}
COVERAGE:{percent%|n/a}
BLOCKING:{description of first critical|none}
```
If Strict TDD active, append one line: `TDD:{evidence:ok|missing}`
No prose, no tables, no headers outside the schema.

## Rules

- ALWAYS read the actual source code — never trust summaries alone
- ALWAYS execute tests — static analysis alone is insufficient
- If the project is React, ALWAYS load and apply `react-doctor`
- A scenario is COMPLIANT only when a covering test PASSES
- Compare against specs first, design second
- CRITICAL blocks archive
- WARNINGS should be fixed but do not necessarily block
- SUGGESTIONS are non-blocking improvements
- DO NOT fix issues here — only report them
- If `react-doctor` finds real issues, mark them clearly so they are corrected in `sdd-apply` before archive
- If Strict TDD is active, load `strict-tdd-verify.md` and execute all extra checks
- If Strict TDD is not active, do not load that module
- Reuse cached testing capabilities whenever possible
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`

## Output contract

Respond ONLY in the schema defined in Step 9. No preamble, no explanation,
no markdown tables or bullets outside the schema. If you add anything else, you are wrong.
