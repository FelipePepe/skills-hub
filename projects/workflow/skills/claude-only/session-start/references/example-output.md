# Example Output (vi-sdd, simulated)

```
## Resumption point — vi-sdd

**Branch:** main · **Last commit:** abc1234 chore: close spec 006
**Uncommitted changes:** 12 untracked files (.artifacts/, .claude/, CLAUDE.md, docs/, specs/, src/, tests/)
**Last session:** 2026-05-21 — Closed spec 006 (OWASP coverage). Macro F1 0.998, 317 tests.
**Codebase graph:** stale (3 commits behind HEAD)

### Project state
- 6 specs closed (001→006). 6-stage pipeline: prepare→scan→validate→dedup→prove→report.
- Macro F1 0.998, 0 FPs, 7 OWASP categories covered. Latest metric is a record.
- No active spec with pending phases.

### Prioritized debt (top 3)
- Calibrate LLM auditor (qwen2.5-coder:7b hallucinates; F1 with auditor drops to 0.76)
- Real CVE OSS fixtures (Heartbleed, getaddrinfo) — spec 004 phase 10.1
- A01 Django/Spring handler collectors (framework detected, handlers not collected)

### Suggested next step
If you want to continue: open spec 007 extending A07/A10 to Java/C#/Go/Rust, or an iterative auditor calibration session (1-2h). If the goal is to consolidate: commit current state (there are docs/, specs/, src/ untracked).

⚠ Engram was outdated as of 2026-05-18 — synced in the previous session. OK.

### Before we start — a few questions:

1. **Goal** — What do you want to accomplish today?
2. **Constraints** — Any deadline, scope limit, or thing to avoid?
3. **Approach** — Should I propose a plan first, or dive straight in?
   - Need SDD cycle? (spec, tasks, phases)
   - Architecture decision that warrants DDIA tradeoff analysis?
   - Something else I should load before starting?
4. **Blockers** — Anything waiting on a PR, external dependency, or another person?
```
