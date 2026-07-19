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
PROJECTS_FILE="$ROOT_DIR/config/projects.json"
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
skills_hub_require_file "$PROJECTS_FILE"
skills_hub_require_file "$OPENCODE_CONFIG"
skills_hub_require_command rsync
skills_hub_require_command node
skills_hub_validate_json "$APPS_FILE"
skills_hub_validate_json "$PROJECTS_FILE"
skills_hub_source_sync_map "$MAP_FILE"

# Invariante: el clon debe estar en disco local.
skills_hub_assert_local "$ROOT_DIR" "clon del repo"

rsync_base=( -a --delete )
rsync_file=( -a )
$DRY_RUN && rsync_base+=( --dry-run --itemize-changes )
$DRY_RUN && rsync_file+=( --dry-run --itemize-changes )
$VERBOSE && rsync_base+=( -v )
$VERBOSE && rsync_file+=( -v )

skills_hub_info "Copiando skills a las apps detectadas...$([[ "$DRY_RUN" == true ]] && echo ' [dry-run]')"

# Resuelve de apps.json + projects.json: id<TAB>installPath<TAB>detectPaths(,)<TAB>sources(,)
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

  declare -A expected_skills=()
  IFS=',' read -r -a source_list <<< "$sources_csv"
  for source_dir in "${source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { skills_hub_warn "source inexistente, se omite -> $abs_source"; continue; }

    while IFS= read -r -d '' skill_dir; do
      skill_name="$(basename "$skill_dir")"
      # Excluir privados/compartidos (mismo criterio que el catalogo).
      [[ "$skill_name" == _* || "$skill_name" == .* ]] && continue
      expected_skills["$skill_name"]=1
      rsync "${rsync_base[@]}" "$skill_dir/" "$install_path/$skill_name/"
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  done

  # Poda de huerfanas: skills del destino que ya no existen en ninguna fuente.
  # Se preservan directorios privados/compartidos (_*, .*), igual que en la copia.
  if [[ -d "$install_path" ]]; then
    while IFS= read -r -d '' installed_dir; do
      installed_name="$(basename "$installed_dir")"
      [[ "$installed_name" == _* || "$installed_name" == .* ]] && continue
      [[ -n "${expected_skills[$installed_name]:-}" ]] && continue
      if [[ "$DRY_RUN" == true ]]; then
        echo "PLAN: rm -rf $installed_dir (huerfana)"
      else
        rm -rf "$installed_dir"
        skills_hub_info "  $app_id: huerfana eliminada -> $installed_name"
      fi
    done < <(find "$install_path" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  fi
  unset expected_skills
done < <(node "$ROOT_DIR/scripts/lib/catalog.mjs" app-sources)

skills_hub_info "Copiando agentes a las apps detectadas...$([[ "$DRY_RUN" == true ]] && echo ' [dry-run]')"

# Extrae de apps.json: id<TAB>agentInstallPath<TAB>detectPaths(,)<TAB>agentSources(,)
# Solo apps con agentSources definido.
while IFS=$'\t' read -r app_id agent_install_path detect_csv agent_sources_csv; do
  [[ -n "$app_id" ]] || continue
  [[ -n "$agent_sources_csv" ]] || continue

  if [[ -n "$APP_FILTER" && "$app_id" != "$APP_FILTER" ]]; then
    continue
  fi

  agent_install_path="$(eval echo "$agent_install_path")"

  detected=false
  IFS=',' read -r -a detect_list <<< "$detect_csv"
  for dp in "${detect_list[@]}"; do
    [[ -n "$dp" ]] || continue
    dp="$(eval echo "$dp")"
    if [[ -e "$dp" ]]; then detected=true; break; fi
  done

  if [[ "$detected" == false && "$INCLUDE_MISSING" == false ]]; then
    skills_hub_info "  $app_id (agentes): no detectada, se omite."
    continue
  fi

  skills_hub_assert_local "$agent_install_path" "destino de agentes '$app_id'"
  $DRY_RUN || mkdir -p "$agent_install_path"

  skills_hub_info "  $app_id (agentes) -> $agent_install_path"

  IFS=',' read -r -a agent_source_list <<< "$agent_sources_csv"
  for source_dir in "${agent_source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    [[ -d "$abs_source" ]] || { skills_hub_warn "agentSource inexistente, se omite -> $abs_source"; continue; }

    while IFS= read -r -d '' agent_file; do
      agent_basename="$(basename "$agent_file")"
      [[ "$agent_basename" == _* || "$agent_basename" == .* ]] && continue
      rsync "${rsync_file[@]}" "$agent_file" "$agent_install_path/$agent_basename"
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -name "*.md" -type f -print0 | sort -z)
  done
done < <(node "$ROOT_DIR/scripts/lib/catalog.mjs" agent-sources)

skills_hub_info "Sincronizando contenido copiable legacy (prompts, etc.)..."
for pair in "${SYNC_PAIRS[@]}"; do
  src_rel="${pair%%::*}"
  dst_abs="${pair##*::}"
  src_abs="$ROOT_DIR/$src_rel"

  [[ -e "$src_abs" ]] || { skills_hub_warn "origen inexistente, se omite -> $src_abs"; continue; }
  skills_hub_assert_local "$dst_abs" "destino legacy"

  if [[ -d "$src_abs" ]]; then
    dst_dir="$dst_abs"
  else
    dst_dir="$(dirname "$dst_abs")"
  fi
  if [[ ! -d "$dst_dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "PLAN: mkdir -p $dst_dir"
    else
      mkdir -p "$dst_dir"
    fi
  fi

  if [[ -d "$src_abs" ]]; then
    echo "SYNC: $src_abs/ -> $dst_abs/"
    rsync "${rsync_base[@]}" "$src_abs/" "$dst_abs/"
  else
    echo "SYNC: $src_abs -> $dst_abs"
    rsync "${rsync_file[@]}" "$src_abs" "$dst_abs"
  fi
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
