# judgment-day — output formats

## Approved flow

```markdown
## Judgment Day — {target}

### Round {N} — Verdict

| Finding | Judge A | Judge B | Severity | Status |
|---------|---------|---------|----------|--------|
| Missing null check in auth.go:42 | ✅ | ✅ | CRITICAL | Confirmed |
| Race condition in worker.go:88 | ✅ | ❌ | WARNING (real) | Suspect (A only) |
| Windows volume root edge case | ❌ | ✅ | WARNING (theoretical) | INFO — reported |
| Naming mismatch in handler.go:15 | ❌ | ✅ | SUGGESTION | Suspect (B only) |

### Fixes Applied (Round {N})
- `auth.go:42` — Added nil check

### Round {N+1} — Re-judgment
- Judge A: PASS ✅
- Judge B: PASS ✅

### JUDGMENT: APPROVED ✅
Both judges pass clean.
```

## Escalated flow

```markdown
## Judgment Day — {target}

### JUDGMENT: ESCALATED ⚠️

User chose to stop after {N} fix iterations. Manual review required.

### Remaining Issues
| Finding | Judge A | Judge B | Severity |
|---------|---------|---------|----------|
| {description} | ✅ | ✅ | CRITICAL |

### History
- Round 1: {N} confirmed issues found
- Fix 1: applied {list}
```
