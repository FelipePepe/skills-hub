#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_FILE="$ROOT_DIR/.github/branch-protection.main.json"
REPO_SLUG="${1:-}"
BRANCH="${2:-main}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh no esta instalado." >&2
  exit 1
fi

if [[ -z "$REPO_SLUG" ]]; then
  echo "Uso: $0 <owner/repo> [branch]" >&2
  echo "Ejemplo: $0 acme/skills-hub main" >&2
  exit 2
fi

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "ERROR: no existe $POLICY_FILE" >&2
  exit 1
fi

echo "[skills-hub] Aplicando branch protection en $REPO_SLUG:$BRANCH"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/$REPO_SLUG/branches/$BRANCH/protection" \
  --input "$POLICY_FILE" >/dev/null

echo "[skills-hub] Branch protection aplicada correctamente."
