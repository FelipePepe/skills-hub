#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

mapfile -t skill_files < <(find "$ROOT_DIR/skills" -name SKILL.md | sort)

if [[ "${#skill_files[@]}" -eq 0 ]]; then
  echo "ERROR: no se encontraron skills" >&2
  exit 1
fi

for file in "${skill_files[@]}"; do
  line_count="$(wc -l < "$file" | tr -d ' ')"
  if (( line_count > 300 )); then
    echo "ERROR: SKILL.md supera 300 lineas: ${file#"$ROOT_DIR"/} ($line_count)" >&2
    exit 1
  fi
done

if rg -n '\bmente\.casa\b|\bname:\s*mente-docs\b' "$ROOT_DIR/skills" "$ROOT_DIR/opencode" >/dev/null 2>&1; then
  echo "ERROR: quedan referencias obsoletas a mente/mente.casa. Usa atlas/atlas.casa." >&2
  rg -n '\bmente\.casa\b|\bname:\s*mente-docs\b' "$ROOT_DIR/skills" "$ROOT_DIR/opencode" >&2
  exit 1
fi

if rg -n 'skills sugeridas si existen: .*sdd-proposal|skill \*\*`sdd-proposal`' \
  "$ROOT_DIR/opencode" "$ROOT_DIR/skills" \
  --glob '!skills/copilot-only/sdd-proposal/SKILL.md' >/dev/null 2>&1; then
  echo "ERROR: quedan referencias activas a sdd-proposal. Usa sdd-propose salvo alias legacy." >&2
  rg -n 'skills sugeridas si existen: .*sdd-proposal|skill \*\*`sdd-proposal`' \
    "$ROOT_DIR/opencode" "$ROOT_DIR/skills" \
    --glob '!skills/copilot-only/sdd-proposal/SKILL.md' >&2
  exit 1
fi
