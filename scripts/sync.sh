#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"

if [[ ! -f "$MAP_FILE" ]]; then
  echo "ERROR: No existe $MAP_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$MAP_FILE"

DRY_RUN=false
VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --verbose) VERBOSE=true ;;
    *)
      echo "Uso: $0 [--dry-run] [--verbose]" >&2
      exit 2
      ;;
  esac
done

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync no esta instalado." >&2
  exit 1
fi

echo "[skills-hub] Iniciando sincronizacion..."

for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  if [[ ! -d "$src_abs" ]]; then
    echo "WARN: origen inexistente, se omite -> $src_abs"
    continue
  fi

  mkdir -p "$dst_abs"

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

echo "[skills-hub] Sincronizacion finalizada."
