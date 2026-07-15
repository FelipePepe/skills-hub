# Strict TDD Module — Verify Phase

> Load this module only when Strict TDD Mode is enabled and a test runner is available.

## TDD Verification Philosophy

Strict TDD verification asks not only “does the code work?” but also “was it built correctly under TDD?”.

Your job is to validate the apply-phase TDD evidence against the actual repository and test execution.

## Step 5a: TDD compliance check

Read `apply-progress` and validate the **TDD Cycle Evidence** table.

For each task row:
- **RED** → must indicate a test was written; verify the test file exists
- **GREEN** → must indicate the test passed; verify it still passes now
- **TRIANGULATE** → verify the number of distinct cases is credible for the spec scenarios
- **SAFETY NET** → verify existing tests were run for modified files
- **REFACTOR** → record but do not try to prove subjectively

Flag:
- missing TDD table → **CRITICAL**
- referenced test file missing → **CRITICAL**
- “green” test now failing → **CRITICAL**
- inadequate triangulation or wrong safety-net claims → **WARNING**

## Step 5b: Test layer validation

Classify change-related tests into:
- unit
- integration
- E2E
- unknown

Report:
- test count by layer
- file count by layer
- tool used by each layer

Flag only as **SUGGESTION** when important behaviors are covered only by lower layers despite richer tooling being available.

## Step 5d: Changed-file coverage

When coverage tooling exists:
- run coverage
- filter to changed files from apply-progress
- report line %, branch %, and uncovered line ranges per changed file

Rating guide:
- ≥95% → ✅ Excellent
- ≥80% → ⚠️ Acceptable
- <80% → ⚠️ Low

Coverage is informative; low coverage is a **WARNING**, not a CRITICAL blocker.

## Step 5e: Quality metrics

If tools exist, run on changed files where possible:
- linter
- type checker

Flag:
- linter/type errors in changed files → **WARNING**
- style-only issues or warnings → **SUGGESTION**

## Step 5f: Assertion quality audit

Scan changed tests for meaningless or weak assertions.

Critical failures:
- tautologies like `expect(true).toBe(true)`
- assertions that never exercise production code
- ghost loops whose assertions may never run
- tests that pass only because the target path never executes

Warnings:
- empty-result assertions without non-empty companion tests
- type-only assertions without value assertions
- smoke-test-only cases
- implementation-detail coupling
- mock-heavy tests with weak behavioral assertions

Record:
- file
- line
- offending assertion or pattern
- why it is weak
- severity

## Required report additions

When Strict TDD is active, include the extra sections from:
- `references/strict-tdd-tables.md`

## Rules

- ALWAYS validate TDD evidence against reality
- ALWAYS run assertion-quality checks
- Tautology assertions are **CRITICAL**
- Missing coverage or quality tools is not a failure by itself
- DO NOT fix issues — only report them
