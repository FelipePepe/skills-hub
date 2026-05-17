---
name: sdd-spec
description: >
  Write specifications with requirements and scenarios (delta specs for changes).
  Trigger: When the orchestrator launches you to write or update specs for a change.
license: MIT
metadata:
  authors: [gentleman-programming, SandMan Owl]
  harness: agnostic
  version: "2.0"
---

## Purpose

Write delta specs. Take the proposal's Capabilities section and produce structured ADDED/MODIFIED/REMOVED requirements with scenarios.

## Persistence (MANDATORY)

Follow `skills/_shared/sdd-phase-common.md` Section B (retrieval) and C (persistence).

| Mode | Where to write spec |
|---|---|
| `engram` | `sdd/{change-name}/spec` in Engram topic key |
| `openspec` | `openspec/changes/{change-name}/specs/{domain}/spec.md` |
| `hybrid` | BOTH engram + openspec |
| `none` | Return only, create nothing |

## Process

1. **Read proposal's Capabilities section** — this is your primary contract
2. **Identify affected domains** from Capabilities (NEW → full spec, MODIFIED → delta spec)
3. **Read existing specs** (only for openspec/hybrid mode)
4. **Write delta spec**
5. **Persist artifact** (MANDATORY) — topic_key: `sdd/{change-name}/spec`, type: `architecture`
6. **Return summary** per Section D of `sdd-phase-common.md`

## Delta Spec Format

```markdown
# Delta for {Domain}

## ADDED Requirements

### Requirement: {Name}
{Description using RFC 2119 keywords}
#### Scenario: {Name}
- GIVEN {precondition}
- WHEN {action}
- THEN {outcome}
- AND {additional outcome}

## MODIFIED Requirements

### Requirement: {Existing Name}
{FULL updated requirement text — copy entire block, edit, add note}
(Previously: {one-line summary})

## REMOVED Requirements

### Requirement: {Name}
(Reason: {why deprecated})
```

### MODIFIED Requirements — CRITICAL

Copy FULL requirement block from existing spec → paste under MODIFIED → edit → add `(Previously: ...)` line. Partial blocks lose content at archive time.

### NEW Specs (no existing)

Create full spec: Purpose + Requirements + Scenarios. Not a delta.

## Rules

- Use Given/When/Then for scenarios
- Use RFC 2119 keywords (MUST, SHALL, SHOULD, MAY)
- Every requirement MUST have ≥1 scenario (happy path + edge case)
- Keep scenarios TESTABLE — someone can write automated test from each
- DO NOT include implementation details
- MODIFIED = FULL block (copy → edit → note)
- Adding new behavior without changing existing → use ADDED, not MODIFIED
- **Size budget**: under 650 words, prefer tables over narrative, 3-5 lines per scenario
- Apply any `rules.specs` from `openspec/config.yaml`

## RFC 2119 Keywords

| Keyword | Meaning |
|---|---|
| MUST / SHALL | Absolute requirement |
| MUST NOT / SHALL NOT | Absolute prohibition |
| SHOULD | Recommended, exceptions possible |
| SHOULD NOT | Not recommended, may be acceptable |
| MAY | Optional |

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
