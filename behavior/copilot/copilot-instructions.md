# Agent Constitution — Global
# Source of truth for all sessions. Applied without exception.
# Hooks: ~/.copilot/installed-plugins/ | Rules: ~/.copilot/rules/

---

## Identity and Environment

- Private intranet `.casa` on maya (192.168.1.55) + NAS
- Multi-user, no internet exposure
- Secrets vault: Infisical at http://infisical.casa
- Documentation: Obsidian vault at http://mente.casa
- Portal: http://portal.casa

## Base Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 22, TypeScript strict |
| Backend | Hono + Zod |
| Frontend | React + Vite |
| AI Agent | LangGraph + Ollama local |
| DB | SQLite (better-sqlite3) |
| Vector | hnswlib-node |
| Package manager | pnpm (workspaces) |
| Containers | Docker Compose |
| CI/CD | GitHub Actions + casa deploy |

## Code Principles

- **TypeScript strict** always — no `any`, no `as unknown`
- **Functional** over classes when possible
- **Zod** for input and config validation
- **Comments only** when code needs clarification — do not comment the obvious
- **Minimal impact** — surgical changes, no unsolicited refactors
- **No laziness** — solve the root problem, do not patch symptoms

## Output Contract — Token Budget

Output tokens are the most expensive. Every reply must respect:

- Lead with the answer. No preamble, no restating the request, no closing recap.
- Shortest useful reply by default; expand only on explicit request.
- Never echo unchanged code, file contents, or command output — reference `path:line` instead.
- Show diffs or edited lines only, never full files.
- No option menus unless there is a real fork with tradeoffs; give one recommendation.
- Lists max 3 items unless asked; prose over headers/tables for simple answers.
- At most one clarifying question, only when truly blocked.

## Mandatory Workflow

See skill `project-workflow` for the full flow:
```
Vault (Infisical) → SDD → GitFlow feature branch → Implement → Verify → PR → Deploy
```

## Domain-Specific Rules

Load based on context:
- `~/.copilot/rules/api.md` — REST/HTTP conventions
- `~/.copilot/rules/db.md` — SQLite, migrations, queries
- `~/.copilot/rules/security.md` — auth, secrets, permissions
- `~/.copilot/rules/testing.md` — vitest, coverage, TDD
- `~/.copilot/rules/typescript.md` — TS patterns, types, generics
- `~/.copilot/rules/intranet.md` — .casa infrastructure

---

## Context Protocol — Optional Layers

Detect before activating layer skills:

### 🏠 Casa layer (private intranet)

**Active when** (first match wins):
1. `.casa` file exists at project root
2. Project references `*.casa` domains (maya.casa, infisical.casa, etc.)
3. User explicitly mentions "intranet", "maya", or "casa project"

**Available skills:** `casa-vault`, `casa-deploy`, `casa-domain`, `casa-atlas`, `infisical-vault`

**Rule:** If context is NOT .casa, do not suggest or use these skills. Ignore silently.

### 💼 Work layer (work / external projects)

**Active when:** No .casa context signals, or user says "work project".

**Active skills:** Universal only (SDD, code-reviewer, test-runner, etc.)

> To add a new project to the casa layer: `echo "casa" > .casa` at the project root.

---

## Skills — Auto-load by Context

Load the matching skill BEFORE taking action. Multiple skills can apply simultaneously.

### Session lifecycle
| Context | Skill |
|---------|-------|
| Session start | `session-start` |
| Task complete or session close | `session-end` |

### SDD cycle
| Context | Skill |
|---------|-------|
| Any SDD command (init/new/apply/verify/archive/status) | `sdd` |
| Creating or improving AI agent skills | `skill-creator` |
| Finding or installing skills | `find-skills` |
| Auditing or restructuring the skills catalog | `skills-catalog-maintainer` |

### Code quality
| Context | Skill |
|---------|-------|
| Code review, PR audit, before merge | `code-reviewer` |
| Security audit, red team, pentest, auth code | `red-team-offensive` |
| Adversarial dual review, "judgment day" | `judgment-day` |
| React debugging, re-renders, hooks, hydration | `react-doctor` |
| SQLite schema, migrations, query optimization | `db-architect` |
| Running tests, coverage, CI failures | `test-runner` |

### Workflow
| Context | Skill |
|---------|-------|
| Creating a PR, GitFlow branch preparation | `branch-pr` |
| Building an MCP server | `mcp-builder` |
| OpenAI API, model selection, SDK usage | `openai-docs` |

### HyperFrames & animation
| Context | Skill |
|---------|-------|
| HyperFrames compositions, CLI | `hyperframes-cli` |
| GSAP animations | `gsap` |
| Anime.js animations | `animejs` |
| Lottie animations | `lottie` |
| Three.js / WebGL | `three` |
| CSS animations / WAAPI | `css-animations` |
| Tailwind CSS v4 in HyperFrames | `tailwind` |
| Remotion → HyperFrames conversion | `remotion-to-hyperframes` |
| Website → HyperFrames conversion | `website-to-hyperframes` |

---

## Session Lifecycle

Follow the `session-start` and `session-end` skills for the complete protocol.

Key invariants:
- Run `gitflow-check.sh` before any code change — create the correct branch if needed
- Save to engram on each architecture decision, significant file change, or non-obvious discovery
- Session is not closed until `engram-mem_session_summary` has been called

Commits must include the trailer:
```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

After finishing a feature → open a PR, never merge directly:
```bash
gh pr create --base develop --title "<type>: <description>"
```
