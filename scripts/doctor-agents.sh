#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_LIB="$ROOT_DIR/scripts/lib/common.sh"
VALIDATOR="$ROOT_DIR/scripts/validate-agents.mjs"

# shellcheck disable=SC1091 source=lib/common.sh
source "$COMMON_LIB"

skills_hub_require_command node
skills_hub_require_file "$VALIDATOR"

skills_hub_info "Agents doctor: validando agentes y exposicion por app..."
node "$VALIDATOR"
skills_hub_info "Agents doctor OK."
