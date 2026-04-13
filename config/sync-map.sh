#!/usr/bin/env bash

# shellcheck shell=bash

# Mapeos de sincronizacion para skills-hub.
# Formato de cada item en SYNC_PAIRS:
#   "<origen_relativo>::<destino_absoluto>"

SYNC_PAIRS=(
  "skills/common::/home/sandman/.copilot/skills"
  "skills/copilot-only::/home/sandman/.copilot/skills"
  "skills/common::/home/sandman/.claude/skills"
  "skills/claude-only::/home/sandman/.claude/skills"
  "prompts::/home/sandman/.config/Code/User/prompts"
)
