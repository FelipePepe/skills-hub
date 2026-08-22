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

# Extrae metadata.version del frontmatter YAML de un SKILL.md. Devuelve "?"
# si el fichero no existe o no tiene ese campo.
skills_hub_skill_version() {
  local file="${1:?missing SKILL.md path}"
  local version=""
  if [[ -f "$file" ]]; then
    version="$(awk '/^---[[:space:]]*$/{c++; next} c==1' "$file" \
      | grep -m1 -E '^[[:space:]]*version:' \
      | sed -E 's/^[[:space:]]*version:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')"
  fi
  echo "${version:-?}"
}

skills_hub_source_sync_map() {
  local map_file="${1:?missing sync map path}"
  # shellcheck disable=SC1090
  source "$map_file"
}

# Aborta si la ruta vive en un filesystem de red (NAS). Invariante del proyecto:
# todo (clon y destinos de instalacion) debe quedar en disco local de la maquina.
# Detecta por TIPO de filesystem (no por ruta hardcodeada) usando findmnt.
skills_hub_assert_local() {
  local target="${1:?missing path}"
  local label="${2:-ruta}"

  command -v findmnt >/dev/null 2>&1 || {
    skills_hub_warn "findmnt no disponible: no se puede verificar que '$target' sea local."
    return 0
  }

  # Resuelve al mount mas cercano aunque el path aun no exista.
  local probe="$target"
  while [[ ! -e "$probe" && "$probe" != "/" ]]; do
    probe="$(dirname "$probe")"
  done

  # findmnt --target puede devolver varias lineas si hay mounts apilados
  # (p. ej. autofs + cifs sobre el mismo punto). Cualquier capa de red basta
  # para considerar la ruta remota.
  local fstype
  while IFS= read -r fstype; do
    [[ -n "$fstype" ]] || continue
    case "$fstype" in
      nfs | nfs4 | cifs | smb | smb2 | smb3 | smbfs | fuse.sshfs | afs | 9p)
        skills_hub_die "$label en filesystem de red ($fstype): $target. Debe estar en disco local (sin NAS). Clona el repo localmente."
        ;;
    esac
  done < <(findmnt -nro FSTYPE --target "$probe" 2>/dev/null || true)
}
