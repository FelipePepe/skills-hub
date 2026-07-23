# Skills Token Audit

Baseline measurement of the token cost of the skill catalog, taken before any
reduction work. Two costs are tracked separately because they hit different
places:

- **Listing cost** — every skill's `name` + `description` is loaded into the
  system prompt on every session, whether or not the skill is used. This is
  fixed, unavoidable overhead per turn.
- **Body cost** — a skill's full `SKILL.md` content is only loaded when the
  skill actually triggers. Its size matters only for that skill's own
  invocations, not for every session.

Reduction work should prioritize listing cost first (paid by every session)
before trimming skill bodies (paid only on use).

## Methodology

- Source: `node scripts/skill-registry.mjs list --json` (existing repo
  tooling — computes `approxTokens` per file as `content.length / 4`,
  Claude's own tokenizer isn't public so this is the same char/4 heuristic
  the registry already uses elsewhere).
- Scope: the **effective set exposed to the `claude` app** — i.e. after
  override resolution (`claude-only` wins over `common` where both exist),
  matching what actually lands in `~/.claude/skills` and therefore in a
  Claude Code session's system prompt.
- Description tokens = `description.length / 4` (character count of the
  frontmatter `description` field only).
- Full-file tokens = `approxTokens` from the registry (entire `SKILL.md`
  content, frontmatter included).

## Summary (claude app)

| Metric | Value |
|---|---|
| Skills exposed | 42 |
| Listing cost (all descriptions, paid every session) | ~1,930 tokens |
| Body cost if every skill were loaded in one session | ~48,241 tokens |
| Avg description | ~46 tokens / ~193 chars |
| Avg body | ~1,148 tokens / ~152 lines |

For reference, the same catalog exposed to other apps:

| App | Skills | Listing cost | Total body cost |
|---|---:|---:|---:|
| `claude` | 42 | ~1,930 tok | ~48,241 tok |
| `agents` | 32 | ~1,538 tok | ~37,240 tok |
| `copilot` | 2 | ~126 tok | ~2,542 tok |

## Full table (claude app, sorted by body size)

| Skill | Scope | Lines | Desc tokens (~) | Full-file tokens (~) |
|---|---|---:|---:|---:|
| `session-start` | workflow/claude-only | 249 | 58 | 3053 |
| `mcp-builder` | casa/common | 240 | 36 | 2248 |
| `session-end` | workflow/claude-only | 175 | 75 | 2216 |
| `atlas-docs` | casa/common | 260 | 40 | 2052 |
| `sdd` | workflow/common | 255 | 45 | 2020 |
| `sdd-spec` | workflow/common | 219 | 40 | 1838 |
| `compliance-ops` | workflow/common | 92 | 67 | 1786 |
| `sdd-apply` | workflow/common | 153 | 44 | 1673 |
| `sdd-verify` | workflow/common | 210 | 40 | 1652 |
| `redis-cache` | workflow/common | 185 | 43 | 1634 |
| `sdd-onboard` | workflow/common | 197 | 41 | 1583 |
| `issue-creation` | workflow/claude-only | 224 | 29 | 1502 |
| `sdd-propose` | workflow/common | 167 | 37 | 1444 |
| `sdd-tasks` | workflow/common | 174 | 39 | 1426 |
| `find-skills` | workflow/common | 147 | 37 | 1339 |
| `sdd-design` | workflow/common | 159 | 43 | 1293 |
| `sdd-archive` | workflow/common | 133 | 41 | 1227 |
| `judgment-day` | workflow/common | 148 | 50 | 1119 |
| `codebase-memory` | workflow/claude-only | 83 | 54 | 1114 |
| `react-doctor` | casa/common | 131 | 46 | 1100 |
| `sdd-init` | workflow/common | 151 | 38 | 1077 |
| `sdd-explore` | workflow/common | 114 | 46 | 998 |
| `red-team-offensive` | casa/common | 101 | 55 | 947 |
| `eu-gdpr` | workflow/common | 77 | 44 | 853 |
| `work-unit-commits` | workflow/claude-only | 87 | 33 | 797 |
| `eu-ai-act` | workflow/common | 76 | 44 | 758 |
| `enrich-us` | workflow/common | 81 | 72 | 741 |
| `openai-docs` | casa/common | 82 | 46 | 700 |
| `skills-catalog-maintainer` | casa/common | 82 | 34 | 692 |
| `db-architect` | workflow/common | 86 | 47 | 651 |
| `skill-creator` | workflow/common | 91 | 44 | 633 |
| `chained-pr` | workflow/claude-only | 51 | 31 | 626 |
| `headroom` | workflow/claude-only | 41 | 47 | 617 |
| `comment-writer` | workflow/claude-only | 75 | 31 | 602 |
| `cognitive-doc-design` | workflow/claude-only | 82 | 32 | 595 |
| `skill-registry` | workflow/claude-only | 52 | 31 | 577 |
| `gitflow` | workflow/claude-only | 75 | 56 | 568 |
| `test-runner` | workflow/common | 64 | 55 | 514 |
| `poc-init` | casa/claude-only | 70 | 48 | 508 |
| `code-reviewer` | workflow/common | 58 | 52 | 496 |
| `casa-ops` | casa/common | 33 | 85 | 490 |
| `critical-advisor` | workflow/common | 67 | 54 | 482 |

## Findings

**Listing cost (~1,930 tokens total) is skewed but not dominated by one
skill.** The top 8 descriptions (`casa-ops`, `session-end`, `enrich-us`,
`compliance-ops`, `session-start`, `gitflow`, `red-team-offensive`,
`test-runner`, `codebase-memory`) each run 200+ chars and together account for
~490 of the 1,930 listing tokens (~25%). Anthropic's own guidance (surfaced
during the lidr-specboot comparison) is that a `description` should state
*only* the trigger condition, not summarize the workflow — several of these
(`casa-ops`, `compliance-ops`, `enrich-us`) currently do both.

**Body cost is dominated by the `sdd-*` family.** Nine `sdd-*` skills
(`sdd`, `sdd-spec`, `sdd-apply`, `sdd-verify`, `sdd-onboard`, `sdd-propose`,
`sdd-tasks`, `sdd-design`, `sdd-archive`) total ~13,650 tokens — over a
quarter of the entire 48,241-token catalog body — but each only loads on its
own trigger, so this matters only when the SDD cycle is active, not as fixed
per-session overhead.

**`session-start` (3,053 tok) and `session-end` (2,216 tok) are the two most
expensive single files**, and unlike most skills they trigger at the
start/end of nearly every session — closer to fixed cost than the `sdd-*`
family in practice.

**Two skills (`skills-catalog-maintainer`, `find-skills`) plus the general
catalog itself overlap in purpose** (discovering/auditing skills) — worth a
closer look for redundancy in the next pass, not measured here.

## Candidates for the next pass (not yet acted on)

1. Trim the 8 descriptions above 200 chars to trigger-only phrasing (est.
   saving: ~150-250 listing tokens, recurring every session).
2. Review `session-start`/`session-end` bodies for content that could move to
   `references/` (progressive disclosure) since they're near-fixed cost.
3. Check `sdd-*` family for shared boilerplate that could move into
   `_shared/sdd-phase-common.md` instead of being repeated per phase file
   (some of this already exists — verify coverage).
