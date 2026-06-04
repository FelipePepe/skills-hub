---
name: react-doctor
description: >
  Diagnoses problems and bad patterns in React applications: render loops,
  poorly defined effects, unnecessary derived state, incorrect memoization,
  oversized components, hydration issues, performance, and basic accessibility.
  Trigger: when the user asks to review a React app, debug strange behavior,
  audit performance/rendering, or improve React component health.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.1"
---

## When to Use

- The user wants to review the technical health of a React app
- There is strange behavior: re-renders, flicker, loops, hydration, stale state
- Auditing components before merge or refactor
- Questions about hooks, memoization, lifting state, derived state, or composition

## When NOT to Use

- **Not** for creating a new app from scratch: use the appropriate bootstrap skill
- **Not** for purely backend, infrastructure, or bundling bugs unrelated to React
- **Not** for discussing only visual style without functional or architectural impact

---

## Quick Decision Rule

- If the core problem is **React behavior, structure, or performance** → `react-doctor`
- If the core problem is **repo tooling** → `repo-tooling` or equivalent
- If the core problem is **git/release flow** → `gitflow` or workflow skill

Reference:
- `references/checklist.md`

---

## Diagnostic Protocol

### Step 1 — Identify the main symptom

Classify the problem into one of these categories:
- excessive re-renders
- poorly defined `useEffect`
- derived or duplicate state
- useless or missing memoization
- oversized or tightly coupled component
- hydration / SSR mismatch
- broken accessibility or interaction
- bottlenecks in large lists or trees

### Step 2 — Read the component and its immediate context

Review:
- input props
- hooks used
- effect dependencies
- parent/child composition
- state origin
- side effects

Do not diagnose React by looking at a single line out of context.

### Step 3 — Look for React anti-patterns

Pay special attention to:
- `useEffect` syncing derived state that could be calculated at render time
- `useEffect` with incorrect or unstable dependencies
- `useMemo` / `useCallback` added without real benefit
- local state duplicating server data, props, or external cache
- components doing too many things at once
- unstable keys in lists
- business logic embedded in JSX that is hard to test
- handlers recreated in cascades unnecessarily in large trees

### Step 4 — Prioritize the real problem

Classify findings:
- **CRITICAL** → functional bug, loop, broken hydration, data loss, or blocked UX
- **WARNING** → poor performance, high coupling, unnecessary complexity, significant debt
- **SUGGESTION** → structural improvement or non-urgent simplification

### Step 5 — Propose the correct treatment

Choose the minimum adequate intervention:
- remove derived state and calculate at render
- reduce or correct a `useEffect`
- move logic to a hook or pure function
- split component by responsibilities
- memoize only where it reduces real work
- virtualize or paginate large lists
- fix keys, refs, or SSR boundaries

## Review Checklist

Use the full checklist from:
- `references/checklist.md`

Minimum core to always review:
- Is there state that can be derived at render?
- Are there effects that are actually computation?
- Are hook dependencies correct?
- Does the memoization have a measurable reason?
- Does the component mix too many responsibilities?
- Do lists use stable keys?
- Is there a risk of hydration mismatch?

## Useful Heuristics

- If a value can be calculated from current props/state, it probably doesn't need `useState`
- If a `useEffect` only copies data from A to B, it probably isn't needed
- If `useMemo` wraps trivial logic, it probably adds noise
- If a component clearly exceeds a single responsibility, it probably needs extraction
- If the render depends on objects/functions recreated at every level, review stability and real cost

## Anti-patterns

- fixing everything with more `useEffect`
- adding `useMemo` and `useCallback` "just in case"
- duplicating remote/local state without a clear strategy
- blaming React when the problem is data structure or component design
- recommending huge refactors when a small, localized change would suffice

## Output contract

```
SYMPTOM:{one-line description}
CRITICAL:{n} WARNING:{n} SUGGESTION:{n}
[component:line] {severity}: {problem} — {minimum fix}
ORDER:{step1 → step2|none}
```
One finding per line. Omit severity rows with zero findings. No prose outside this format.
