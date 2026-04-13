#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"

echo "[skills-hub] Lint: validando sintaxis Bash..."
bash -n "$ROOT_DIR/scripts/check.sh"
bash -n "$ROOT_DIR/scripts/sync.sh"
bash -n "$ROOT_DIR/scripts/lint.sh"
bash -n "$ROOT_DIR/scripts/doctor.sh"
bash -n "$ROOT_DIR/scripts/setup-branch-protection.sh"
bash -n "$ROOT_DIR/config/sync-map.sh"

if command -v shellcheck >/dev/null 2>&1; then
  echo "[skills-hub] Lint: ejecutando shellcheck..."
  shellcheck "$ROOT_DIR/scripts/check.sh" "$ROOT_DIR/scripts/sync.sh" "$ROOT_DIR/scripts/lint.sh" "$ROOT_DIR/scripts/doctor.sh"
  shellcheck "$ROOT_DIR/scripts/setup-branch-protection.sh"
else
  echo "WARN: shellcheck no esta instalado. Se omite este paso localmente."
fi

if [[ ! -f "$MAP_FILE" ]]; then
  echo "ERROR: No existe $MAP_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$MAP_FILE"

echo "[skills-hub] Lint: validando formato de SYNC_PAIRS..."
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

echo "[skills-hub] Lint OK."
