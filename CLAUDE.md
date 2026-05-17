# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`skills-hub` is a centralized repository that serves as the single source of truth for AI agent skills and synchronization tooling. It maintains 37+ harness-agnostic skills and exposes them to local AI apps (GitHub Copilot, Claude Code, Pi, OpenCode) via symlinks/junctions.

**Architecture**: `skills/common/` (portable skills — WHAT) + `skills/adapters/{harness}/` (harness-specific implementations — HOW) + `scripts/` + `bin/` (installer CLI).

## Directory Structure

- `skills/common/` — 37+ harness-agnostic skills (one folder per skill with a `SKILL.md`)
- `skills/common/_shared/` — Shared contracts: engram-convention, openspec-convention, persistence-contract, sdd-phase-common, skill-resolver, harness-adapter-contract
- `skills/adapters/{pi,opencode,claude}/` — Harness-specific adapter implementations
- `skills/copilot-only/` — Copilot/OpenCode-specific skills (not portable)
- `skills/claude-only/` — Claude Code-specific skills
- `bin/skills-hub.js` — Official CLI entrypoint (`skills-hub` command)
- `scripts/link-skills.mjs` — Core installer logic (symlinks/junctions)
- `scripts/lib/` — Shared library: `common.sh`, `link-skills-cli.mjs`, `link-skills-config.mjs`, `link-skills-core.mjs`
- `config/apps.json` — Manifest of detectable apps and their source/target mappings
- `config/sync-map.sh` — Legacy sync mappings (`SYNC_PAIRS` array)
- `prompts/` — Global prompts and instructions for VS Code
- `opencode/` — Managed configuration fragments for OpenCode
- `.github/workflows/` — CI: `quality.yml`, `pr-branch-policy.yml`, `release.yml`

## Skill Contract

Each skill is a folder with a `SKILL.md` containing YAML frontmatter (`name`, `description`, `harness`). Rules:

- Folder name and frontmatter `name` must match
- Harness-agnostic skills require `harness: agnostic` in frontmatter and zero platform-specific references
- Max 300 lines per `SKILL.md`; modularize into `references/` if larger
- One canonical skill name per directory; no duplicates within a single app's exposed set

## Key Commands

```bash
# CLI (main entrypoint)
pnpm skills-hub status [--app=<id>]
pnpm skills-hub install [--dry-run] [--replace] [--app=<id>]

# Validation (run before PR)
./scripts/doctor-skills.sh   # audit catalog: folder/frontmatter alignment, collisions
./scripts/doctor.sh          # general health checks
./scripts/lint.sh            # bash syntax, node syntax, validate-skills, shellcheck
./scripts/check.sh           # validate symlink plan + legacy content drift

# Synchronization
./scripts/sync.sh            # rsync legacy content + run installer
./scripts/sync.sh --dry-run  # preview without touching disk
```

## Architecture

### Installer Model

The installer (`scripts/link-skills.mjs` + `bin/skills-hub.js`) reads `config/apps.json` which defines:
- **Apps**: `copilot`, `claude`, `agents`, `pi`, `opencode` — each with `detectPaths`, `installPath`, `sources`, and optional `adapterPath`
- **Strategy**: per-skill symlinks (Linux) / junctions (Windows), not directory copies
- **Safety**: skips existing non-symlink paths, backs up config files before modification

### Apps Configuration (`config/apps.json`)

| App | Sources | Target |
|-----|---------|--------|
| `copilot` | `common` + `copilot-only` | `~/.copilot/skills` |
| `claude` | `common` + `claude-only` | `~/.claude/skills` |
| `agents` | `common` | `~/.agents/skills` |
| `pi` | `common` + `adapters/pi` | `~/.pi/agent` (symlinks + TypeScript extensions) |
| `opencode` | `common` + `adapters/opencode` | `~/.config/opencode` (JSON merge + managed MD block) |

### SDD Pipeline

```
init -> explore -> propose -> spec -> tasks -> apply -> verify -> archive
                                    -> design
```

Each phase is a sub-agent with isolated context. The `sdd` orchestrator coordinates without executing.

## Branching (GitFlow)

- `main` — production releases
- `develop` — integration for next release
- `feature/*` from `develop` -> PR to `develop`
- `release/vX.Y.Z` from `develop` -> PR to `main`
- `hotfix/*` from `main` -> PR to `main`

Enforced by `.github/workflows/pr-branch-policy.yml`. Direct commits to `main` or `develop` are prohibited.

## CI

- **Quality** (`quality.yml`): runs on push to `main` and all PRs. Installs `shellcheck`, then runs `./scripts/lint.sh`.
- **PR Branch Policy** (`pr-branch-policy.yml`): validates branch name patterns and base branch pairing on every PR.
- **Release** (`release.yml`): triggered by `v*` tags, publishes a GitHub release with auto-generated notes.

## Skill Authoring Convention: Compact Rules

Every skill's `SKILL.md` MUST follow the compact rules pattern:

1. **Frontmatter** — `name`, `description` (with trigger), `license`, `metadata.author`, `metadata.version`, `metadata.harness`
2. **Body** — max ~1200 bytes. What to do, persistence contract, process steps, rules, model hints.
3. **Detail** — move framework-specific, verbose examples, edge cases to `references/`
4. **No raw SKILL.md paths in delegations** — sub-agents receive compact rules, not file paths

Before adding new skills or editing existing ones, run:
```bash
./scripts/doctor-skills.sh   # catches >300 line violations
./scripts/lint.sh             # semantic validation
```

Skills exceeding ~1200 bytes should be reviewed for compaction. Run `wc -c` to check.

## Contributing Rules

- Small, explicit changes only. No large bulk edits.
- Never hardcode paths outside `config/sync-map.sh`.
- All Bash scripts must use `set -euo pipefail`.
- Avoid `rsync --delete` for destructive operations.
- Keep `bin/skills-hub.js` and `scripts/link-skills.mjs` in sync when changing installer logic.
- Treat `skills/` as canonical source; app paths are exposure targets, not maintenance sites.
- Use `pnpm` for JS/TS skill setup; document `minimumReleaseAge: 10080` for bootstrap skills.
