#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

source "$COMMON_LIB"

skills_hub_info "Lint: validando sintaxis Bash..."
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find "$ROOT_DIR/scripts" "$ROOT_DIR/config" -type f \( -name '*.sh' \) -print0 | sort -z)
node --check "$ROOT_DIR/scripts/link-skills.mjs"
skills_hub_validate_json "$APPS_FILE"

if command -v shellcheck >/dev/null 2>&1; then
  skills_hub_info "Lint: ejecutando shellcheck..."
  while IFS= read -r -d '' file; do
    shellcheck "$file"
  done < <(find "$ROOT_DIR/scripts" "$ROOT_DIR/config" -type f \( -name '*.sh' \) -print0 | sort -z)
else
  skills_hub_warn "shellcheck no esta instalado. Se omite este paso localmente."
fi

skills_hub_require_file "$MAP_FILE"
skills_hub_source_sync_map "$MAP_FILE"

skills_hub_info "Lint: validando formato de SYNC_PAIRS..."
if [[ "${#SYNC_PAIRS[@]}" -eq 0 ]]; then
  echo "ERROR: SYNC_PAIRS esta vacio" >&2
  exit 1
fi

declare -A seen
for pair in "${SYNC_PAIRS[@]}"; do
  if [[ "$pair" != *"::"* ]]; then
    echo "ERROR: formato invalido en SYNC_PAIRS: $pair" >&2
    exit 1
  fi

  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"

  if [[ -z "$src_rel" || -z "$dst_abs" ]]; then
    echo "ERROR: mapeo incompleto en SYNC_PAIRS: $pair" >&2
    exit 1
  fi

  if [[ "$dst_abs" != /* ]]; then
    echo "ERROR: destino debe ser ruta absoluta: $pair" >&2
    exit 1
  fi

  if [[ -n "${seen[$pair]:-}" ]]; then
    echo "ERROR: mapeo duplicado en SYNC_PAIRS: $pair" >&2
    exit 1
  fi
  seen[$pair]=1
done

skills_hub_info "Lint OK."
