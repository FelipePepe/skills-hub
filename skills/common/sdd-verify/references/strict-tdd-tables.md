# sdd-verify — strict TDD report tables

## Required sections when Strict TDD is active

```markdown
### TDD Compliance
| Check | Result | Details |
|-------|--------|---------|
| TDD Evidence reported | ✅ / ❌ | {Found in apply-progress / Missing} |
| All tasks have tests | ✅ / ❌ | {N}/{total} tasks have test files |
| RED confirmed (tests exist) | ✅ / ⚠️ | {N}/{total} test files verified |
| GREEN confirmed (tests pass) | ✅ / ❌ | {N}/{total} tests pass on execution |
| Triangulation adequate | ✅ / ⚠️ / ➖ | {N} tasks triangulated / {N} single-case |
| Safety Net for modified files | ✅ / ⚠️ | {N}/{total} modified files had safety net |

**TDD Compliance**: {N}/{total} checks passed

---

### Test Layer Distribution
| Layer | Tests | Files | Tools |
|-------|-------|-------|-------|
| Unit | {N} | {N} | {tool} |
| Integration | {N} | {N} | {tool or "not installed"} |
| E2E | {N} | {N} | {tool or "not installed"} |
| **Total** | **{N}** | **{N}** | |

---

### Changed File Coverage
| File | Line % | Branch % | Uncovered Lines | Rating |
|------|--------|----------|-----------------|--------|
| `path/to/file.ext` | 95% | 90% | — | ✅ Excellent |
| `path/to/other.ext` | 82% | 75% | L45-48, L62 | ⚠️ Acceptable |
| `path/to/new.ext` | 100% | 100% | — | ✅ Excellent |

**Average changed file coverage**: {N}%
{or "Coverage analysis skipped — no coverage tool detected"}

---

### Assertion Quality
| File | Line | Assertion | Issue | Severity |
|------|------|-----------|-------|----------|
| `path/test.ts` | 15 | `expect(true).toBe(true)` | Tautology — proves nothing | CRITICAL |
| `path/test.ts` | 23 | `expect(result).toEqual([])` | Empty without companion non-empty test | WARNING |
| `path/test.ts` | 31 | `expect(result).toBeDefined()` | Type-only — no value asserted | WARNING |

**Assertion quality**: {N} CRITICAL, {N} WARNING
{or "✅ All assertions verify real behavior"}

---

### Quality Metrics
**Linter**: ✅ No errors / ⚠️ {N} warnings / ❌ {N} errors / ➖ Not available
**Type Checker**: ✅ No errors / ❌ {N} errors / ➖ Not available
```
