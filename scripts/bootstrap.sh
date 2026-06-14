#!/usr/bin/env bash
# Bootstrap script: builds external tools (grafos) and syncs skills-hub.
# Safe to run multiple times — all steps are idempotent.
#
# Usage:
#   ./scripts/bootstrap.sh [--grafos-dir=/path/to/grafos] [--dry-run] [--skip-build] [--skip-sync]

set -euo pipefail

# shellcheck disable=SC1091 source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SKILLS_HUB_DIR="$(skills_hub_root_dir)"

# ── Args ──────────────────────────────────────────────────────────────────────

GRAFOS_DIR=""
DRY_RUN=false
SKIP_BUILD=false
SKIP_SYNC=false

for arg in "$@"; do
  case "$arg" in
    --grafos-dir=*) GRAFOS_DIR="${arg#*=}" ;;
    --grafos-dir)   ;;  # handled by next iteration — not supported, use = form
    --dry-run)      DRY_RUN=true ;;
    --skip-build)   SKIP_BUILD=true ;;
    --skip-sync)    SKIP_SYNC=true ;;
    *) skills_hub_warn "Unknown arg: $arg" ;;
  esac
done

# Default: sibling directory named "grafos"
if [[ -z "$GRAFOS_DIR" ]]; then
  GRAFOS_DIR="$(dirname "$SKILLS_HUB_DIR")/grafos"
fi

GRAFOS_DIR="$(realpath "$GRAFOS_DIR")"

# ── Info ──────────────────────────────────────────────────────────────────────

skills_hub_info "Bootstrap"
skills_hub_info "  skills-hub : $SKILLS_HUB_DIR"
skills_hub_info "  grafos     : $GRAFOS_DIR"
[[ "$DRY_RUN" == "true" ]] && skills_hub_info "  mode       : dry-run"

# ── 1. Build grafos MCP ───────────────────────────────────────────────────────

if [[ "$SKIP_BUILD" == "false" ]]; then
  if [[ -d "$GRAFOS_DIR/mcp" ]]; then
    skills_hub_info "Building grafos MCP..."
    if [[ "$DRY_RUN" == "false" ]]; then
      (cd "$GRAFOS_DIR/mcp" && pnpm install --frozen-lockfile && pnpm build)
    else
      skills_hub_info "  [dry-run] cd $GRAFOS_DIR/mcp && pnpm install && pnpm build"
    fi
  else
    skills_hub_warn "grafos/mcp not found at $GRAFOS_DIR/mcp — skipping build"
  fi
else
  skills_hub_info "Skipping grafos build (--skip-build)"
fi

# ── 2. Sync skills-hub ────────────────────────────────────────────────────────

if [[ "$SKIP_SYNC" == "false" ]]; then
  skills_hub_info "Syncing skills..."
  if [[ "$DRY_RUN" == "false" ]]; then
    (cd "$SKILLS_HUB_DIR" && pnpm skills-hub sync)
  else
    skills_hub_info "  [dry-run] pnpm skills-hub sync"
  fi
else
  skills_hub_info "Skipping skills sync (--skip-sync)"
fi

# ── 3. Patch MCP configs ──────────────────────────────────────────────────────

skills_hub_info "Patching MCP configs..."
if [[ "$DRY_RUN" == "false" ]]; then
  node "$SKILLS_HUB_DIR/scripts/patch-mcp.mjs" --grafos-dir="$GRAFOS_DIR"
else
  skills_hub_info "  [dry-run] patch ~/.claude.json + ~/.vscode/mcp/config.json"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

skills_hub_info "Bootstrap complete."
