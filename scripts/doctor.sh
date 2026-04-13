#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"

echo "[skills-hub] Doctor: verificando entorno local..."

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync no esta instalado." >&2
  exit 1
fi

if [[ ! -f "$MAP_FILE" ]]; then
  echo "ERROR: No existe $MAP_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$MAP_FILE"

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
    echo "WARN: destino inexistente -> $dst_abs"
    echo "      sync.sh lo creara automaticamente con mkdir -p"
  fi
done

if [[ "$errors" -ne 0 ]]; then
  echo "[skills-hub] Doctor detecto errores de configuracion local."
  exit 1
fi

echo "[skills-hub] Doctor OK."
