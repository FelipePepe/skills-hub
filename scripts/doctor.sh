#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
APPS_FILE="$ROOT_DIR/config/apps.json"
LINKER="$ROOT_DIR/scripts/link-skills.mjs"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

source "$COMMON_LIB"

APP_FILTER=""
INCLUDE_MISSING=false

for arg in "$@"; do
  case "$arg" in
    --app=*) APP_FILTER="${arg#--app=}" ;;
    --include-missing) INCLUDE_MISSING=true ;;
    --help|-h)
      cat <<EOF
Uso: $0 [--app=<id>] [--include-missing]
EOF
      exit 0
      ;;
    *)
      echo "Uso: $0 [--app=<id>] [--include-missing]" >&2
      exit 2
      ;;
  esac
done

skills_hub_info "Doctor: verificando entorno local..."

skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_require_file "$MAP_FILE"
skills_hub_require_file "$APPS_FILE"
skills_hub_validate_json "$APPS_FILE"

skills_hub_source_sync_map "$MAP_FILE"

linker_args=( status )
if [[ -n "$APP_FILTER" ]]; then
  linker_args+=( "--app=$APP_FILTER" )
fi
if [[ "$INCLUDE_MISSING" == true ]]; then
  linker_args+=( --include-missing )
fi

errors=0
for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  if [[ ! -d "$src_abs" ]]; then
    echo "ERROR: origen inexistente -> $src_abs"
    errors=1
  fi

  if [[ ! -d "$dst_abs" ]]; then
    skills_hub_warn "destino inexistente -> $dst_abs"
    echo "      sync.sh lo creara automaticamente con mkdir -p" >&2
  fi
done

skills_hub_info "Doctor: estado de apps/configuracion enlazada..."
node "$LINKER" "${linker_args[@]}"

if [[ "$errors" -ne 0 ]]; then
  skills_hub_info "Doctor detecto errores de configuracion local."
  exit 1
fi

skills_hub_info "Doctor OK."
