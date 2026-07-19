# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Single source of truth (a GitHub repo) for managing AI assistant skills and distributing them across multiple machines. On each machine you clone the repo to a LOCAL disk and copy the skills into the local directories of installed apps (Copilot, Claude, agents, VS Code/OpenCode). Skills are copied (rsync), not symlinked. Hard invariant: nothing — neither the clone nor any install target — may live on a network filesystem (NAS); the scripts abort on NFS/CIFS/SMB/sshfs.

## Architecture

- `projects/casa/` - skills bound to the `.casa` intranet and home infrastructure
- `projects/workflow/` - portable development, agent, SDD, analysis, and documentation skills
- Each project keeps `skills/common`, `skills/copilot-only`, and `skills/claude-only`
- `agents/common` - cross-platform sub-agent definitions (installed to `~/.claude/agents/`)
- `agents/claude-only` - Claude-specific sub-agent definitions
- `config/projects.json` - canonical project boundaries and skill sources
- `config/apps.json` - manifest defining target apps, their detect paths, install paths, project variants, and agent sources
- `config/sync-map.sh` - legacy copy sync pairs in format `<rel_path>::<abs_path>` for copyable content (e.g., VS Code prompts)
- `scripts/sync.sh` - copy-based installer (rsync) that copies skills from sources to each detected app's installPath and prunes orphan skills no longer present in any source (preserving `_*`/`.*` dirs); enforces the local-only invariant via `skills_hub_assert_local`
- `scripts/install-opencode-config.mjs` - installs OpenCode managed config (json-merge + markdown managed block); the only piece that needs Node merge logic
- `scripts/lib/common.sh` - shared bash helpers, including `skills_hub_assert_local` (NAS guard)
- `bin/skills-hub.js` - official CLI wrapping the installer and all validation scripts
- `opencode/` - managed fragments for OpenCode (`opencode.managed.json` for JSON merge, `AGENTS.md` for markdown managed block)
- `prompts/` - legacy copyable content synced via rsync in `sync.sh`

Key pattern: `scripts/lib/common.sh` provides shared helpers (`skills_hub_info`, `skills_hub_warn`, `skills_hub_die`, `skills_hub_require_command`, `skills_hub_validate_json`, `skills_hub_source_sync_map`, etc.) sourced by all Bash scripts.

## Build and Test

No build step. This is a content + scripting repo.

Pre-PR local validation (in order):
```bash
./scripts/doctor-skills.sh   # catalog semantic validation (naming, duplication, line counts)
./scripts/doctor.sh          # environment + config diagnostics
./scripts/lint.sh            # syntax check (bash -n, node --check, shellcheck, JSON, sync-map format)
./scripts/check.sh           # drift detection between sources and targets
```

Sync operations:
```bash
pnpm skills-hub install          # copy skills to all detected apps
pnpm skills-hub install --dry-run
pnpm skills-hub install --app=copilot
pnpm skills-hub status
pnpm skills-hub doctor
pnpm skills-hub doctor-skills
pnpm skills-hub lint
pnpm skills-hub check
pnpm skills-hub sync [--dry-run]
```

Direct script invocation:
```bash
./scripts/sync.sh --dry-run
./scripts/sync.sh --app=claude
./scripts/check.sh
```

## Conventions

- Every `SKILL.md` must be under 300 lines; if larger, modularize into `references/`
- SKILL.md frontmatter `name` must match the containing directory name exactly
- Agent files (`agents/**/*.md`) must include the Prompt Defense Baseline block (see `projects/workflow/skills/common/_shared/prompt-defense-baseline.md`)
- Agent `name` frontmatter must match the filename (without `.md`)
- Default placement for an agent is `agents/common`; use `agents/claude-only` only when it depends on Claude-specific tooling
- Never hardcode paths outside `config/sync-map.sh`
- All Bash scripts must use `set -euo pipefail`
- `SYNC_PAIRS` format: `"<rel_path>::<abs_path>"` — destination must be absolute
- Naming: use `atlas`/`atlas.casa`, never `mente`/`mente.casa`
- Naming: use `sdd-propose` as canonical; the legacy `sdd-proposal` alias was removed
- ONLY use `pnpm` — `npm` and `npx` are FORBIDDEN. Use `pnpm` and `pnpm dlx` instead. This applies to skill examples, scripts, and all commands in this repo.
- Use `pnpm` in JS/TS skill examples; document `minimumReleaseAge: 10080` for bootstrap/setup skills
- Place `.casa` skills in `projects/casa/skills/common` and portable skills in `projects/workflow/skills/common`; use the selected project's `copilot-only`/`claude-only` only when it truly depends on that platform
- Skills are installed by COPY (rsync), never symlinks; after editing a skill, re-run `pnpm skills-hub sync` to propagate
- Never let the clone or any install target live on a network filesystem (NAS); `skills_hub_assert_local` enforces this
- If changing installer logic, keep `bin/skills-hub.js` and `scripts/sync.sh` aligned

## GitFlow

- `main` — production releases only, no direct commits
- `develop` — integration branch, no direct commits
- `feature/*` — from `develop`, PR to `develop`
- `release/vX.Y.Z` — from `develop`, PR to `main`
- `hotfix/*` — from `main`, PR to `main`

See `GITFLOW.md`, `BRANCH_PROTECTION.md`, `RELEASING.md` for full guides.

## Release

Semantic Versioning + Keep a Changelog. See `RELEASING.md` for the full checklist. Key steps:

```bash
./scripts/doctor.sh && ./scripts/lint.sh && ./scripts/check.sh
git checkout develop && git pull && git checkout -b release/vX.Y.Z
# update CHANGELOG.md: move "Sin publicar" entries to new version section
git add CHANGELOG.md && git commit -m "chore(release): prepare vX.Y.Z"
git push -u origin release/vX.Y.Z && gh pr create --base main --title "release: vX.Y.Z"
# after merge: git tag -a vX.Y.Z && git push origin vX.Y.Z
```

CI: `quality.yml` runs `./scripts/lint.sh` on push to `main` and all PRs. `release.yml` auto-publishes GitHub releases on `v*` tags via `softprops/action-gh-release`.

## Important files to know

- `.github/copilot-instructions.md` — global agent rules for this repo
- `.github/CODEOWNERS` — repository ownership (currently `@FelipePepe`)
- `.github/dependabot.yml` — weekly GitHub Actions dependency updates
- `.github/pull_request_template.md` — PR template with validation checklist
- `CHANGELOG.md` — keep "Sin publicar" section at top, release links at bottom
