#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${SRC_DIR:-/home/sandman/.copilot/skills}"
DST_DIR="$ROOT_DIR/skills/copilot-only"

DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *)
      echo "Uso: $0 [--dry-run]" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: no existe el origen $SRC_DIR" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync no esta instalado." >&2
  exit 1
fi

mkdir -p "$DST_DIR"

rsync_args=(
  -a
  --delete
  --exclude='.DS_Store'
  --exclude='*.bak-*'
)

if [[ "$DRY_RUN" == true ]]; then
  rsync_args+=( --dry-run --itemize-changes )
fi

echo "[skills-hub] Importando $SRC_DIR/ -> $DST_DIR/"
rsync "${rsync_args[@]}" "$SRC_DIR/" "$DST_DIR/"
echo "[skills-hub] Importacion finalizada."
