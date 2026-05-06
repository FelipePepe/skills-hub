#!/usr/bin/env bash

# shellcheck shell=bash

# Mapeos de sincronizacion legacy para contenido copiable.
# Las skills y la configuracion de OpenCode se instalan con
# `scripts/link-skills.mjs` para evitar duplicaciones en disco.
# Formato de cada item en SYNC_PAIRS:
#   "<origen_relativo>::<destino_absoluto>"

SYNC_PAIRS=(
  "prompts::/home/sandman/.config/Code/User/prompts"
)
