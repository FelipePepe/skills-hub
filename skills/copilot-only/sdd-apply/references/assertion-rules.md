# strict-tdd — assertion quality rules

## Banned patterns

Never write:
- tautologies like `expect(true).toBe(true)`
- empty collection assertions without proving why the result is empty
- type-only assertions without asserting actual value/behavior
- ghost loops where assertions may never execute
- tests that pass because the target path never runs

## What makes a real assertion

A real assertion must:
1. call production code
2. assert a specific output/behavior
3. fail if the production logic is wrong

Examples:
- `expect(calculateDiscount(100, 10)).toBe(10)`
- `expect(screen.getByText('Welcome, John')).toBeInTheDocument()`
- `assert response.status_code == 403`

## Empty collection rule

An empty result assertion is only valid when the setup explicitly proves that the empty case is the intended behavior.

## Smoke-test rule

`render()` + `toBeInTheDocument()` alone is not enough unless it proves meaningful behavior.

## Mock hygiene

Avoid mock-heavy tests with weak behavioral assertions. Prefer behavior over internal call counting.

## Implementation-detail coupling

Avoid assertions that only verify CSS classes, mock call counts, or internal state without proving user-visible behavior.
