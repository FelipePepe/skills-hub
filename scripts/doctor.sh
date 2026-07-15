#!/usr/bin/env bash
set -euo pipefail

# Diagnostico de entorno local: herramientas, deteccion de apps, invariante de
# localidad (sin NAS) y auditoria del catalogo de skills.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
APPS_FILE="$ROOT_DIR/config/apps.json"
PROJECTS_FILE="$ROOT_DIR/config/projects.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"
SKILLS_DOCTOR="$ROOT_DIR/scripts/doctor-skills.sh"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

skills_hub_info "Doctor: verificando entorno local..."

skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_require_file "$MAP_FILE"
skills_hub_require_file "$APPS_FILE"
skills_hub_require_file "$PROJECTS_FILE"
skills_hub_require_file "$SKILLS_DOCTOR"
skills_hub_validate_json "$APPS_FILE"
skills_hub_validate_json "$PROJECTS_FILE"
node "$ROOT_DIR/scripts/lib/catalog.mjs" check
skills_hub_source_sync_map "$MAP_FILE"

skills_hub_assert_local "$ROOT_DIR" "clon del repo"

errors=0

skills_hub_info "Doctor: deteccion de apps y destinos..."
while IFS=$'\t' read -r app_id install_path detect_csv; do
  [[ -n "$app_id" ]] || continue
  install_path="$(eval echo "$install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done

  state=$([[ "$detected" == true ]] && echo "detected" || echo "missing")
  echo "- $app_id: $state"
  [[ -n "$install_path" ]] && echo "  install: $install_path"
  [[ -d "$install_path" ]] && skills_hub_assert_local "$install_path" "destino de '$app_id'"
done < <(
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const P = "linux";
    for (const app of data.apps) {
      const install = app.installPath?.[P] ?? "";
      const detect = Array.isArray(app.detectPaths?.[P]) ? app.detectPaths[P].join(",") : "";
      console.log([app.id, install, detect].join("\t"));
    }
  ' "$APPS_FILE"
)

skills_hub_info "Doctor: rutas de instalacion de agentes..."
while IFS=$'\t' read -r app_id agent_install_path detect_csv; do
  [[ -n "$app_id" ]] || continue
  agent_install_path="$(eval echo "$agent_install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done

  state=$([[ "$detected" == true ]] && echo "detected" || echo "missing")
  echo "- $app_id (agents): $state"
  echo "  agents: $agent_install_path"
  [[ -d "$agent_install_path" ]] && skills_hub_assert_local "$agent_install_path" "destino de agentes '$app_id'"
done < <(
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const P = "linux";
    for (const app of data.apps) {
      if (!app.agentInstallPath) continue;
      const install = app.agentInstallPath[P] ?? "";
      const detect = Array.isArray(app.detectPaths?.[P]) ? app.detectPaths[P].join(",") : "";
      console.log([app.id, install, detect].join("\t"));
    }
  ' "$APPS_FILE"
)

skills_hub_info "Doctor: verificando origenes/destinos legacy..."
for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  if [[ ! -e "$src_abs" ]]; then
    echo "ERROR: origen inexistente -> $src_abs"
    errors=1
  fi
  if [[ ! -d "$dst_abs" ]]; then
    skills_hub_warn "destino inexistente -> $dst_abs (sync.sh lo creara)"
  fi
done

skills_hub_info "Doctor: auditoria del catalogo de skills..."
bash "$SKILLS_DOCTOR"

if [[ "$errors" -ne 0 ]]; then
  skills_hub_info "Doctor detecto errores de configuracion local."
  exit 1
fi

skills_hub_info "Doctor OK."
