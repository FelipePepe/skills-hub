#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
LINKER="$ROOT_DIR/scripts/link-skills.mjs"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

source "$COMMON_LIB"

DRY_RUN=false
VERBOSE=false
APP_FILTER=""
REPLACE=false
INCLUDE_MISSING=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --verbose) VERBOSE=true ;;
    --replace) REPLACE=true ;;
    --include-missing) INCLUDE_MISSING=true ;;
    --app=*) APP_FILTER="${arg#--app=}" ;;
    --help|-h)
      cat <<EOF
Uso: $0 [--dry-run] [--verbose] [--replace] [--include-missing] [--app=<id>]
EOF
      exit 0
      ;;
    *)
      echo "Uso: $0 [--dry-run] [--verbose] [--replace] [--include-missing] [--app=<id>]" >&2
      exit 2
      ;;
  esac
done

skills_hub_require_file "$MAP_FILE"
skills_hub_require_file "$APPS_FILE"
skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_validate_json "$APPS_FILE"
skills_hub_source_sync_map "$MAP_FILE"

skills_hub_info "Iniciando instalacion de skills por enlaces..."
linker_args=( install )
if [[ "$DRY_RUN" == true ]]; then
  linker_args+=( --dry-run )
fi
if [[ "$REPLACE" == true ]]; then
  linker_args+=( --replace )
fi
if [[ "$INCLUDE_MISSING" == true ]]; then
  linker_args+=( --include-missing )
fi
if [[ -n "$APP_FILTER" ]]; then
  linker_args+=( "--app=$APP_FILTER" )
fi
if ! node "$LINKER" "${linker_args[@]}"; then
  echo "ERROR: fallo la instalacion por enlaces" >&2
  exit 1
fi

skills_hub_info "Sincronizando contenido copiable legacy..."

for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  if [[ ! -d "$src_abs" ]]; then
    echo "WARN: origen inexistente, se omite -> $src_abs"
    continue
  fi

  if [[ ! -d "$dst_abs" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "PLAN: mkdir -p $dst_abs"
    else
      mkdir -p "$dst_abs"
    fi
  fi

  rsync_args=( -a --delete )
  if [[ "$DRY_RUN" == true ]]; then
    rsync_args+=( --dry-run --itemize-changes )
  fi
  if [[ "$VERBOSE" == true ]]; then
    rsync_args+=( -v )
  fi

  echo "SYNC: $src_abs/ -> $dst_abs/"
  rsync "${rsync_args[@]}" "$src_abs/" "$dst_abs/"
done

skills_hub_info "Instalacion/sincronizacion finalizada."
