#!/usr/bin/env bash

set -euo pipefail

skills_hub_root_dir() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cd "$script_dir/.." && pwd
}

skills_hub_info() {
  echo "[skills-hub] $*"
}

skills_hub_warn() {
  echo "WARN: $*" >&2
}

skills_hub_die() {
  echo "ERROR: $*" >&2
  exit 1
}

skills_hub_require_command() {
  local cmd="${1:?missing command name}"
  command -v "$cmd" >/dev/null 2>&1 || skills_hub_die "$cmd no esta instalado."
}

skills_hub_require_file() {
  local file="${1:?missing file path}"
  [[ -f "$file" ]] || skills_hub_die "No existe $file"
}

skills_hub_require_dir() {
  local dir="${1:?missing dir path}"
  [[ -d "$dir" ]] || skills_hub_die "No existe $dir"
}

skills_hub_validate_json() {
  local file="${1:?missing json file}"
  node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$file" \
    >/dev/null 2>&1 || skills_hub_die "JSON invalido en $file"
}

skills_hub_source_sync_map() {
  local map_file="${1:?missing sync map path}"
  # shellcheck disable=SC1090
  source "$map_file"
}
