# Strict TDD Module — Apply Phase

> Load this module only when Strict TDD Mode is enabled and a test runner is available.

## TDD Philosophy

TDD is software design driven by tests. Tests define contracts and behavior; code is the response.

### The Three Laws

1. Do NOT write production code until you have a failing test
2. Do NOT write more test than necessary to fail
3. Do NOT write more code than necessary to pass

## TDD Implementation Cycle

For every task, follow this cycle:

```text
FOR EACH TASK:
├── 0. SAFETY NET (existing files only)
│   ├── Run existing relevant tests
│   ├── If any fail → stop and report pre-existing failure
│   └── Capture baseline
├── 1. UNDERSTAND
│   ├── Read task, specs, design, and existing patterns
│   └── Choose the correct test layer
├── 2. RED
│   ├── Write the failing test first
│   └── Do not proceed until the test exists
├── 3. GREEN
│   ├── Write the minimum code to pass
│   ├── Execute tests
│   └── Do not proceed until tests pass
├── 4. TRIANGULATE
│   ├── Add additional cases to force general logic
│   ├── Minimum: happy path + one different path/edge case
│   └── Skip only for truly structural tasks with explicit reason
├── 5. REFACTOR
│   ├── Improve code without changing behavior
│   ├── Run tests after each refactor step
│   └── Revert refactors that break tests
├── 6. Mark task complete
└── 7. Note deviations or issues
```

## Choosing Test Layer

Use the highest available layer that fits the task:
- pure logic / transforms → unit
- rendering / interaction / state → integration if available, else unit with mocks
- multi-component or API flows → integration if available
- critical end-to-end user journey → E2E if available, else integration, else unit

Never skip a task because a richer layer is unavailable; degrade gracefully.

## Test Execution

Read the test command from cached capabilities first, then config, then project manifests.

During TDD:
- run only the relevant test file or scope
- keep the cycle fast
- full-suite execution belongs to `sdd-verify`

## Pure Function Preference

Prefer pure functions because they are deterministic and easy to test.

## Approval Testing

For refactoring existing behavior:
- write approval tests that capture current behavior
- run them before refactoring
- refactor
- run them again to prove behavior stayed intact
- if behavior must change per spec, update the expectation and re-enter RED/GREEN

## Return Summary Extension

Use the return section template from:
- `references/tdd-report-template.md`

## Assertion Quality Rules

Use the detailed guidance from:
- `references/assertion-rules.md`

Core rule: every assertion must prove real behavior, not merely existence.

## Rules (Strict TDD specific)

- ALWAYS follow the RED → GREEN → TRIANGULATE → REFACTOR loop
- ALWAYS run a safety net when modifying existing files
- ALWAYS triangulate unless the task is truly structural and you justify the skip
- ALWAYS keep tests close to the spec scenarios they prove
- Approval tests are required for risky refactors
- Use the highest suitable test layer available, but degrade gracefully
- Return the TDD evidence section in your summary
