#!/usr/bin/env bash

# shellcheck shell=bash

# Mapeos de sincronizacion legacy para contenido copiable (p. ej. prompts).
# Las skills se copian con `scripts/sync.sh` (rsync) y la configuracion de
# OpenCode se instala con `scripts/install-opencode-config.mjs`.
# Formato de cada item en SYNC_PAIRS:
#   "<origen_relativo>::<destino_absoluto>"

case "${OSTYPE:-}" in
  msys* | cygwin*) _VSCODE_USER_DIR="${APPDATA}/Code/User" ;;
  *)               _VSCODE_USER_DIR="${HOME}/.config/Code/User" ;;
esac

# shellcheck disable=SC2034
SYNC_PAIRS=(
  "prompts::${_VSCODE_USER_DIR}/prompts"
)
