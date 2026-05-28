# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Single source of truth for managing AI assistant skills and synchronizing them to local directories of installed apps (Copilot, Claude, VS Code/OpenCode). Skills are exposed via symlinks/junctions, not copied.

## Architecture

- `skills/common` - cross-platform skills shared across all apps
- `skills/copilot-only` - skills exclusive to GitHub Copilot / OpenCode
- `skills/claude-only` - skills exclusive to Claude
- `config/apps.json` - manifest defining target apps, their detect paths, install paths, and which skill sources they consume
- `config/sync-map.sh` - legacy copy sync pairs in format `<rel_path>::<abs_path>` for content that cannot use symlinks (e.g., VS Code prompts)
- `scripts/link-skills.mjs` + `scripts/lib/` - cross-platform symlink/junction installer (Linux=symlinks, Windows=junctions)
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
pnpm skills-hub install          # install skills via symlinks to all detected apps
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
node ./scripts/link-skills.mjs install --dry-run
./scripts/sync.sh --dry-run
```

## Conventions

- Every `SKILL.md` must be under 300 lines; if larger, modularize into `references/`
- SKILL.md frontmatter `name` must match the containing directory name exactly
- Never hardcode paths outside `config/sync-map.sh`
- All Bash scripts must use `set -euo pipefail`
- `SYNC_PAIRS` format: `"<rel_path>::<abs_path>"` — destination must be absolute
- Naming: use `atlas`/`atlas.casa`, never `mente`/`mente.casa`
- Naming: use `sdd-propose` as canonical, `sdd-proposal` is legacy alias only
- Use `pnpm` in JS/TS skill examples; document `minimumReleaseAge: 10080` for bootstrap/setup skills
- If changing installer logic, keep `bin/skills-hub.js` and `scripts/link-skills.mjs` aligned

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
