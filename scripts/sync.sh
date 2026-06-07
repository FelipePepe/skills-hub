#!/usr/bin/env bash
set -euo pipefail

# Instalador de skills por COPIA local (rsync).
#
# Modelo del proyecto: skills-hub es la fuente unica (GitHub) y cada maquina
# clona el repo en disco LOCAL y copia las skills a los directorios de cada app.
# No se usan symlinks ni rutas de red (NAS): asi las skills quedan dentro de la
# maquina e independientes del clon. Tras editar una skill, re-ejecuta `sync`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$ROOT_DIR/config/sync-map.sh"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"
OPENCODE_CONFIG="$ROOT_DIR/scripts/install-opencode-config.mjs"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

DRY_RUN=false
VERBOSE=false
APP_FILTER=""
INCLUDE_MISSING=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --verbose) VERBOSE=true ;;
    --include-missing) INCLUDE_MISSING=true ;;
    --app=*) APP_FILTER="${arg#--app=}" ;;
    --help|-h)
      cat <<EOF
Uso: $0 [--dry-run] [--verbose] [--include-missing] [--app=<id>]

Copia las skills del repo a los directorios locales de cada app detectada.
EOF
      exit 0
      ;;
    *)
      echo "Uso: $0 [--dry-run] [--verbose] [--include-missing] [--app=<id>]" >&2
      exit 2
      ;;
  esac
done

skills_hub_require_file "$MAP_FILE"
skills_hub_require_file "$APPS_FILE"
skills_hub_require_file "$OPENCODE_CONFIG"
skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_validate_json "$APPS_FILE"
skills_hub_source_sync_map "$MAP_FILE"

# Invariante: el clon debe estar en disco local.
skills_hub_assert_local "$ROOT_DIR" "clon del repo"

rsync_base=( -a --delete )
$DRY_RUN && rsync_base+=( --dry-run --itemize-changes )
$VERBOSE && rsync_base+=( -v )

skills_hub_info "Copiando skills a las apps detectadas...$([[ "$DRY_RUN" == true ]] && echo ' [dry-run]')"

# Extrae de apps.json: id<TAB>installPath<TAB>detectPaths(,)<TAB>sources(,)
# Solo apps con al menos una source de skills.
while IFS=$'\t' read -r app_id install_path detect_csv sources_csv; do
  [[ -n "$app_id" ]] || continue
  [[ -n "$sources_csv" ]] || continue

  if [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]]; then
    continue
  fi

  install_path="$(eval echo "$install_path")"

  # Deteccion de la app (alguno de sus detectPaths existe).
  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done

  if [[ "$detected" == false && "$INCLUDE_MISSING" == false ]]; then
    skills_hub_info "  $app_id: no detectada, se omite (usa --include-missing para forzar)."
    continue
  fi

  skills_hub_assert_local "$install_path" "destino de '$app_id'"
  $DRY_RUN || mkdir -p "$install_path"

  skills_hub_info "  $app_id -> $install_path"

  IFS=',' read -r -a source_list <<< "$sources_csv"
  for source_dir in "${source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { skills_hub_warn "source inexistente, se omite -> $abs_source"; continue; }

    while IFS= read -r -d '' skill_dir; do
      skill_name="$(basename "$skill_dir")"
      # Excluir privados/compartidos (mismo criterio que el catalogo).
      [[ "$skill_name" == _* || "$skill_name" == .* ]] && continue
      rsync "${rsync_base[@]}" "$skill_dir/" "$install_path/$skill_name/"
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

skills_hub_info "Copiando agents a las apps detectadas...$([[ "$DRY_RUN" == true ]] && echo ' [dry-run]')"

# Extrae de apps.json: id<TAB>agentInstallPath<TAB>detectPaths(,)<TAB>agentSources(,)
# Solo apps con al menos una source de agents.
while IFS=$'\t' read -r app_id install_path detect_csv sources_csv; do
  [[ -n "$app_id" ]] || continue
  [[ -n "$sources_csv" ]] || continue

  if [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]]; then
    continue
  fi

  install_path="$(eval echo "$install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done

  if [[ "$detected" == false && "$INCLUDE_MISSING" == false ]]; then
    skills_hub_info "  $app_id agents: app no detectada, se omite (usa --include-missing para forzar)."
    continue
  fi

  skills_hub_assert_local "$install_path" "destino de agents '$app_id'"
  if [[ ! -d "$install_path" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "PLAN: mkdir -p $install_path"
    else
      mkdir -p "$install_path"
    fi
  fi

  skills_hub_info "  $app_id agents -> $install_path"

  IFS=',' read -r -a source_list <<< "$sources_csv"
  for source_dir in "${source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { skills_hub_warn "agent source inexistente, se omite -> $abs_source"; continue; }

    while IFS= read -r -d '' agent_file; do
      agent_name="$(basename "$agent_file")"
      [[ "$agent_name" == _* || "$agent_name" == .* ]] && continue
      if [[ "$DRY_RUN" == true && ! -d "$install_path" ]]; then
        echo "PLAN: copy $agent_file -> $install_path/$agent_name"
      else
        rsync "${rsync_base[@]}" "$agent_file" "$install_path/$agent_name"
      fi
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
  done
done < <(
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const P = "linux";
    for (const app of data.apps) {
      const sources = Array.isArray(app.agentSources) ? app.agentSources.join(",") : "";
      if (!sources) continue;
      const install = app.agentInstallPath?.[P] ?? "";
      const detect = Array.isArray(app.detectPaths?.[P]) ? app.detectPaths[P].join(",") : "";
      console.log([app.id, install, detect, sources].join("\t"));
    }
  ' "$APPS_FILE"
)

skills_hub_info "Sincronizando contenido copiable legacy (prompts, etc.)..."
for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  [[ -d "$src_abs" ]] || { skills_hub_warn "origen inexistente, se omite -> $src_abs"; continue; }
  skills_hub_assert_local "$dst_abs" "destino legacy"

  if [[ ! -d "$dst_abs" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "PLAN: mkdir -p $dst_abs"
    else
      mkdir -p "$dst_abs"
    fi
  fi

  echo "SYNC: $src_abs/ -> $dst_abs/"
  rsync "${rsync_base[@]}" "$src_abs/" "$dst_abs/"
done

skills_hub_info "Instalando configuracion gestionada (OpenCode)..."
config_args=()
$DRY_RUN && config_args+=( --dry-run )
node "$OPENCODE_CONFIG" "${config_args[@]}"

skills_hub_info "Instalando archivos de comportamiento (CLAUDE.md, copilot-instructions.md)..."
behavior_args=()
$DRY_RUN && behavior_args+=( --dry-run )
[[ -n "$APP_FILTER" ]] && behavior_args+=( "--app=$APP_FILTER" )
bash "$SCRIPT_DIR/install-behavior.sh" "${behavior_args[@]}"

skills_hub_info "Sincronizacion finalizada."
