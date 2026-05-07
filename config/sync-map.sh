#!/usr/bin/env bash

# shellcheck shell=bash

# Mapeos de sincronizacion legacy para contenido copiable.
# Las skills y la configuracion de OpenCode se instalan con
# `scripts/link-skills.mjs` para evitar duplicaciones en disco.
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
