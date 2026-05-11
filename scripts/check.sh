#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
LINKER="$ROOT_DIR/scripts/link-skills.mjs"
APPS_FILE="$ROOT_DIR/config/apps.json"
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

skills_hub_require_file "$MAP_FILE"
skills_hub_require_file "$APPS_FILE"
skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_validate_json "$APPS_FILE"
skills_hub_source_sync_map "$MAP_FILE"

skills_hub_info "Verificando drift..."
errors=0

linker_status_args=( status )
linker_install_args=( install --dry-run )
if [[ -n "$APP_FILTER" ]]; then
  linker_status_args+=( "--app=$APP_FILTER" )
  linker_install_args+=( "--app=$APP_FILTER" )
fi
if [[ "$INCLUDE_MISSING" == true ]]; then
  linker_status_args+=( --include-missing )
  linker_install_args+=( --include-missing )
fi

skills_hub_info "Verificando instalacion por enlaces..."
if ! node "$LINKER" "${linker_status_args[@]}"; then
  echo "ERROR: fallo al inspeccionar apps instaladas con link-skills.mjs"
  errors=1
fi

if ! node "$LINKER" "${linker_install_args[@]}"; then
  echo "ERROR: fallo al construir el plan de instalacion de skills"
  errors=1
fi

for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  if [[ ! -d "$src_abs" ]]; then
    echo "ERROR: origen inexistente -> $src_abs"
    errors=1
    continue
  fi

  if [[ ! -d "$dst_abs" ]]; then
    echo "WARN: destino inexistente -> $dst_abs"
    echo "      sync.sh lo creara automaticamente con mkdir -p"
    echo "PLAN: se copiaria $src_abs/ -> $dst_abs/"
    continue
  fi

  tmp_out="$(mktemp)"
  if ! rsync -ani --delete "$src_abs/" "$dst_abs/" > "$tmp_out"; then
    echo "ERROR: fallo rsync al comparar $src_abs con $dst_abs"
    rm -f "$tmp_out"
    errors=1
    continue
  fi

  if [[ -s "$tmp_out" ]]; then
    echo "DRIFT: $src_abs -> $dst_abs"
    cat "$tmp_out"
    errors=1
  else
    echo "OK: $src_abs -> $dst_abs"
  fi

  rm -f "$tmp_out"
done

if [[ "$errors" -ne 0 ]]; then
  skills_hub_info "Drift detectado o errores de configuracion."
  exit 1
fi

skills_hub_info "Todo consistente."
