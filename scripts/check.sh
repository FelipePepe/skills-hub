#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
LINKER="$ROOT_DIR/scripts/link-skills.mjs"

if [[ ! -f "$MAP_FILE" ]]; then
  echo "ERROR: No existe $MAP_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$MAP_FILE"

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync no esta instalado." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node no esta instalado." >&2
  exit 1
fi

echo "[skills-hub] Verificando drift..."
errors=0

echo "[skills-hub] Verificando instalacion por enlaces..."
if ! node "$LINKER" status; then
  echo "ERROR: fallo al inspeccionar apps instaladas con link-skills.mjs"
  errors=1
fi

if ! node "$LINKER" install --dry-run; then
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
    echo "ERROR: destino inexistente -> $dst_abs"
    errors=1
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
  echo "[skills-hub] Drift detectado o errores de configuracion."
  exit 1
fi

echo "[skills-hub] Todo consistente."
