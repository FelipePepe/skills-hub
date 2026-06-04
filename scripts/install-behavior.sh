#!/usr/bin/env bash
set -euo pipefail

# Installs configFiles with strategy "copy" from apps.json.
# Used for plain behavior files (CLAUDE.md, copilot-instructions.md) that
# must be copied as-is, without merge or managed-block logic.
#
# Only processes apps whose detect paths exist on the current machine.
# Skips apps handled by install-opencode-config.mjs (strategy != "copy").

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

DRY_RUN=false
APP_FILTER=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --app=*) APP_FILTER="${arg#--app=}" ;;
  esac
done

skills_hub_require_file "$APPS_FILE"
skills_hub_validate_json "$APPS_FILE"
skills_hub_require_command node

expand_home() {
  local val="$1"
  echo "${val/\~/$HOME}"
}

app_detected() {
  local detect_json="$1"
  local paths
  paths=$(node -e "
    const d = $detect_json;
    const key = process.platform === 'win32' ? 'windows' : 'linux';
    console.log((d[key] || []).join('\n'));
  ")
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    local expanded
    expanded=$(expand_home "$p")
    [[ -e "$expanded" ]] && return 0
  done <<< "$paths"
  return 1
}

app_count=$(node -e "const a=require('$APPS_FILE');console.log(a.apps.length)")

for i in $(seq 0 $((app_count - 1))); do
  app_id=$(node -e "const a=require('$APPS_FILE');console.log(a.apps[$i].id)")
  [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]] && continue

  detect_json=$(node -e "const a=require('$APPS_FILE');console.log(JSON.stringify(a.apps[$i].detectPaths||{}))")
  if ! app_detected "$detect_json"; then
    skills_hub_info "Skipping $app_id (not detected)"
    continue
  fi

  config_count=$(node -e "const a=require('$APPS_FILE');console.log((a.apps[$i].configFiles||[]).length)")
  [[ "$config_count" -eq 0 ]] && continue

  for j in $(seq 0 $((config_count - 1))); do
    strategy=$(node -e "const a=require('$APPS_FILE');console.log(a.apps[$i].configFiles[$j].strategy)")
    [[ "$strategy" != "copy" ]] && continue

    src_rel=$(node -e "const a=require('$APPS_FILE');console.log(a.apps[$i].configFiles[$j].source)")
    target_raw=$(node -e "
      const a=require('$APPS_FILE');
      const t=a.apps[$i].configFiles[$j].target;
      const key=process.platform==='win32'?'windows':'linux';
      console.log(t[key]||'');
    ")

    src_abs="$ROOT_DIR/$src_rel"
    dst_abs=$(expand_home "$target_raw")

    [[ -z "$dst_abs" ]] && { skills_hub_warn "No target for $src_rel on this platform, skipping"; continue; }
    [[ ! -f "$src_abs" ]] && { skills_hub_warn "Source not found: $src_abs, skipping"; continue; }

    skills_hub_assert_local "$dst_abs" "behavior target"

    dst_dir="$(dirname "$dst_abs")"
    if [[ ! -d "$dst_dir" ]]; then
      if $DRY_RUN; then
        echo "PLAN: mkdir -p $dst_dir"
      else
        mkdir -p "$dst_dir"
      fi
    fi

    if $DRY_RUN; then
      echo "PLAN: cp $src_abs -> $dst_abs"
    else
      cp "$src_abs" "$dst_abs"
      skills_hub_info "COPY [$app_id]: $src_rel -> $dst_abs"
    fi
  done
done

skills_hub_info "Behavior files installed."
