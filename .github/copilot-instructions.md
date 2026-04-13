# Project Guidelines

## Scope
- Este repositorio es la fuente unica de verdad para sincronizar skills y prompts hacia destinos locales de Copilot, Claude y VS Code.
- Usa este archivo como regla global para cualquier cambio en `skills/`, `prompts/`, `config/` y `scripts/`.

## Architecture
- `skills/common` contiene contenido compartido.
- `skills/copilot-only` y `skills/claude-only` contienen contenido exclusivo por plataforma.
- `prompts/` contiene prompts e instrucciones de usuario para VS Code.
- `config/sync-map.sh` define todos los mapeos de sincronizacion en `SYNC_PAIRS`; no hardcodear rutas en scripts.
- `scripts/sync.sh` aplica sincronizacion unidireccional con `rsync -a --delete`.
- `scripts/check.sh` valida drift entre origen y destino usando comparacion `rsync -ani --delete`.

## Build and Test
- No hay build de aplicacion en este repo.
- Validar consistencia antes de cambios finales: `./scripts/check.sh`
- Previsualizar sincronizacion: `./scripts/sync.sh --dry-run`
- Aplicar sincronizacion: `./scripts/sync.sh`
- Requisito de entorno: `rsync` debe estar instalado y disponible en `PATH`.

## Conventions
- Mantener scripts Bash con `set -euo pipefail`.
- Mantener formato de mapeo: `"<origen_relativo>::<destino_absoluto>"` en `SYNC_PAIRS`.
- `check.sh` debe fallar si detecta drift o destinos inexistentes.
- `sync.sh` puede crear destino con `mkdir -p`; no eliminar este comportamiento.
- Preferir cambios pequenos y explicitos en mapeos para evitar borrados involuntarios por `--delete`.

## Docs
- Para contexto general del repositorio y estructura, ver `README.md`.