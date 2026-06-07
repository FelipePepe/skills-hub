#!/usr/bin/env bash
set -euo pipefail

# Detecta drift entre el repo (fuente) y las copias instaladas en cada app.
# Como las skills se instalan por COPIA, comparamos contenido con rsync -ani.
# Cualquier diferencia (o un destino que sea symlink) cuenta como drift.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

# shellcheck disable=SC1091 source=lib/common.sh
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

skills_hub_assert_local "$ROOT_DIR" "clon del repo"

skills_hub_info "Verificando drift (repo -> copias instaladas)..."
errors=0

while IFS=$'\t' read -r app_id install_path detect_csv sources_csv; do
  [[ -n "$app_id" ]] || continue
  [[ -n "$sources_csv" ]] || continue
  [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]] && continue

  install_path="$(eval echo "$install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done
  if [[ "$detected" == false && "$INCLUDE_MISSING" == false ]]; then
    echo "SKIP: $app_id (no detectada)"
    continue
  fi

  IFS=',' read -r -a source_list <<< "$sources_csv"
  for source_dir in "${source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { echo "ERROR: source inexistente -> $abs_source"; errors=1; continue; }

    while IFS= read -r -d '' skill_dir; do
      skill_name="$(basename "$skill_dir")"
      [[ "$skill_name" == _* || "$skill_name" == .* ]] && continue
      dst="$install_path/$skill_name"

      if [[ -L "$dst" ]]; then
        echo "DRIFT: $app_id/$skill_name es un symlink (debe ser copia) -> $(readlink "$dst")"
        errors=1
        continue
      fi
      if [[ ! -d "$dst" ]]; then
        echo "DRIFT: $app_id/$skill_name falta en destino ($dst)"
        errors=1
        continue
      fi

      tmp_out="$(mktemp)"
      if ! rsync -ani --delete "$skill_dir/" "$dst/" > "$tmp_out" 2>/dev/null; then
        echo "ERROR: fallo rsync al comparar $skill_dir con $dst"
        errors=1
      elif [[ -s "$tmp_out" ]]; then
        echo "DRIFT: $app_id/$skill_name"
        sed 's/^/    /' "$tmp_out"
        errors=1
      fi
      rm -f "$tmp_out"
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  done
done < <(
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const P = "linux";
    for (const app of data.apps) {
      const sources = Array.isArray(app.sources) ? app.sources.join(",") : "";
      if (!sources) continue;
      const install = app.installPath?.[P] ?? "";
      const detect = Array.isArray(app.detectPaths?.[P]) ? app.detectPaths[P].join(",") : "";
      console.log([app.id, install, detect, sources].join("\t"));
    }
  ' "$APPS_FILE"
)

skills_hub_info "Verificando drift de agentes (repo -> copias instaladas)..."

while IFS=$'\t' read -r app_id agent_install_path detect_csv agent_sources_csv; do
  [[ -n "$app_id" ]] || continue
  [[ -n "$agent_sources_csv" ]] || continue
  [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]] && continue

  agent_install_path="$(eval echo "$agent_install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done
  if [[ "$detected" == false && "$INCLUDE_MISSING" == false ]]; then
    echo "SKIP: $app_id (agentes, no detectada)"
    continue
  fi

  IFS=',' read -r -a agent_source_list <<< "$agent_sources_csv"
  for source_dir in "${agent_source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { echo "ERROR: agentSource inexistente -> $abs_source"; errors=1; continue; }

    while IFS= read -r -d '' agent_file; do
      agent_basename="$(basename "$agent_file")"
      [[ "$agent_basename" == _* || "$agent_basename" == .* ]] && continue
      dst="$agent_install_path/$agent_basename"

      if [[ -L "$dst" ]]; then
        echo "DRIFT: $app_id/agents/$agent_basename es un symlink (debe ser copia)"
        errors=1
        continue
      fi
      if [[ ! -f "$dst" ]]; then
        echo "DRIFT: $app_id/agents/$agent_basename falta en destino ($dst)"
        errors=1
        continue
      fi

      tmp_out="$(mktemp)"
      if ! rsync -ani "$agent_file" "$agent_install_path/" > "$tmp_out" 2>/dev/null; then
        echo "ERROR: fallo rsync al comparar $agent_file con $dst"
        errors=1
      elif [[ -s "$tmp_out" ]]; then
        echo "DRIFT: $app_id/agents/$agent_basename"
        sed 's/^/    /' "$tmp_out"
        errors=1
      fi
      rm -f "$tmp_out"
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -name "*.md" -type f -print0 | sort -z)
  done
done < <(
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const P = "linux";
    for (const app of data.apps) {
      const agentSources = Array.isArray(app.agentSources) ? app.agentSources.join(",") : "";
      if (!agentSources) continue;
      const install = app.agentInstallPath?.[P] ?? "";
      const detect = Array.isArray(app.detectPaths?.[P]) ? app.detectPaths[P].join(",") : "";
      console.log([app.id, install, detect, agentSources].join("\t"));
    }
  ' "$APPS_FILE"
)

for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  [[ -d "$src_abs" ]] || { echo "ERROR: origen inexistente -> $src_abs"; errors=1; continue; }
  if [[ ! -d "$dst_abs" ]]; then
    echo "WARN: destino inexistente -> $dst_abs (sync.sh lo creara)"
    continue
  fi

  tmp_out="$(mktemp)"
  if ! rsync -ani --delete "$src_abs/" "$dst_abs/" > "$tmp_out"; then
    echo "ERROR: fallo rsync al comparar $src_abs con $dst_abs"
    errors=1
  elif [[ -s "$tmp_out" ]]; then
    echo "DRIFT: $src_abs -> $dst_abs"
    sed 's/^/    /' "$tmp_out"
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
