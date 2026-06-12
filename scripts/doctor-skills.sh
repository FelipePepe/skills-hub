#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPS_FILE="$ROOT_DIR/config/apps.json"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

skills_hub_require_command node
skills_hub_require_file "$APPS_FILE"
skills_hub_validate_json "$APPS_FILE"

mapfile -t skill_files < <(find "$ROOT_DIR/skills" -name SKILL.md | sort)
if [[ "${#skill_files[@]}" -eq 0 ]]; then
  skills_hub_die "No se encontraron skills en $ROOT_DIR/skills"
fi

for file in "${skill_files[@]}"; do
  skill_dir="$(dirname "$file")"
  dir_name="$(basename "$skill_dir")"
  frontmatter_name="$(sed -n 's/^name:[[:space:]]*//p' "$file" | head -n 1 | tr -d '"' | xargs)"

  [[ -n "$frontmatter_name" ]] || skills_hub_die "Skill sin frontmatter name: ${file#"$ROOT_DIR"/}"

  if [[ "$frontmatter_name" != "$dir_name" ]]; then
    skills_hub_die "Nombre de carpeta y frontmatter desalineados: ${file#"$ROOT_DIR"/} (dir=$dir_name, name=$frontmatter_name)"
  fi
done

while IFS=$'\t' read -r app_id sources; do
  [[ -n "$app_id" ]] || continue
  declare -A exposed_names=()
  skill_count=0

  IFS=',' read -r -a source_list <<< "$sources"
  for source_dir in "${source_list[@]}"; do
    [[ -n "$source_dir" ]] || continue
    abs_source="$ROOT_DIR/$source_dir"
    skills_hub_require_dir "$abs_source"

    while IFS= read -r -d '' child; do
      skill_name="$(basename "$child")"
      if [[ "$skill_name" == _* ]]; then
        continue
      fi
      skill_file="$child/SKILL.md"

      if [[ ! -f "$skill_file" ]]; then
        skills_hub_die "Directorio de skill sin SKILL.md en fuente de app '$app_id': ${child#"$ROOT_DIR"/}"
      fi

      if [[ -n "${exposed_names[$skill_name]:-}" ]]; then
        # Platform-specific source overrides common — last source wins, no error.
        continue
      fi
      exposed_names[$skill_name]=1
      ((skill_count += 1))
    done < <(find "$abs_source" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  done

  skills_hub_info "Skills doctor: app '$app_id' expone $skill_count skills canonicas."
done < <(
  # shellcheck disable=SC2016
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    for (const app of data.apps) {
      const sources = Array.isArray(app.sources) ? app.sources.join(",") : "";
      console.log(`${app.id}\t${sources}`);
    }
  ' "$APPS_FILE"
)

skills_hub_info "Skills doctor OK."
