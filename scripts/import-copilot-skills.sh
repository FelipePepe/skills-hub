#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"
# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

SRC_DIR="${SRC_DIR:-${HOME}/.copilot/skills}"
DST_DIR="$ROOT_DIR/projects/workflow/skills/copilot-only"

DRY_RUN=false
DELETE=true

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --no-delete) DELETE=false ;;
    --source)
      [[ "$#" -ge 2 ]] || skills_hub_die "--source requiere una ruta"
      SRC_DIR="$2"
      shift
      ;;
    --help|-h)
      cat <<EOF
Uso: $0 [--dry-run] [--no-delete] [--source <ruta>]
EOF
      exit 0
      ;;
    *)
      echo "Uso: $0 [--dry-run]" >&2
      exit 2
      ;;
  esac
  shift
done

skills_hub_require_dir "$SRC_DIR"
skills_hub_require_command rsync

mkdir -p "$DST_DIR"

rsync_args=(
  -a
  --exclude='.DS_Store'
  --exclude='*.bak-*'
)

if [[ "$DELETE" == true ]]; then
  rsync_args+=( --delete )
fi

if [[ "$DRY_RUN" == true ]]; then
  rsync_args+=( --dry-run --itemize-changes )
fi

skills_hub_info "Importando $SRC_DIR/ -> $DST_DIR/"
rsync "${rsync_args[@]}" "$SRC_DIR/" "$DST_DIR/"
skills_hub_info "Importacion finalizada."
