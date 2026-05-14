#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_SLUG="${1:-}"
BRANCH="${2:-main}"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

skills_hub_require_command gh

if [[ -z "$REPO_SLUG" ]]; then
  echo "Uso: $0 <owner/repo> [branch]" >&2
  echo "Ejemplo: $0 acme/skills-hub main" >&2
  exit 2
fi

POLICY_FILE="$ROOT_DIR/.github/branch-protection.$BRANCH.json"
skills_hub_require_file "$POLICY_FILE"
skills_hub_validate_json "$POLICY_FILE"

skills_hub_info "Aplicando branch protection en $REPO_SLUG:$BRANCH"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/$REPO_SLUG/branches/$BRANCH/protection" \
  --input "$POLICY_FILE" >/dev/null

skills_hub_info "Branch protection aplicada correctamente."
