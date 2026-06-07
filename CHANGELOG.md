# Changelog

Todos los cambios notables de este proyecto se documentaran en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

## [2.2.0] - 2026-06-07

### Añadido

- `bin/copilot-credits.js`: nueva CLI local para analizar el consumo de AI Credits de GitHub Copilot. Lee `~/.copilot/session-state/<id>/events.jsonl`, aplica la tabla de precios oficial de GitHub y muestra un resumen por modelo con tokens, créditos y coste en USD. Soporta `--days`, `--model`, `--sessions`, `--json`.
- Comando `copilot-credits` registrado en el campo `bin` de `package.json`.
- Sección `## Análisis de créditos de Copilot` en `README.md` con referencia de uso, ejemplo de salida y explicación de la fuente de datos.

## [2.0.0] - 2026-05-29

### Cambiado

- **Modelo de instalacion: de symlinks a copia.** Las skills ahora se **copian** (rsync) a cada app en `scripts/sync.sh`, en lugar de exponerse por symlink. Quedan en disco local de la maquina e independientes del clon. Tras editar una skill hay que re-ejecutar `sync` (BREAKING: ya no es instantaneo).
- Invariante de localidad: `scripts/lib/common.sh` incorpora `skills_hub_assert_local`, que aborta si el clon o algun destino vive en un filesystem de red (NFS/CIFS/SMB/sshfs). Aplicado en `sync.sh`, `check.sh` y `doctor.sh`.
- `check.sh` detecta drift comparando contenido repo<->copias (rsync -ani) y marca symlinks residuales como drift.
- `bin/skills-hub.js`: `install`/`sync` ejecutan `sync.sh`; `status` reutiliza la deteccion de `doctor.sh`.
- Reclasificacion del catalogo: el grupo SDD y las skills base de Claude se movieron de `copilot-only` a `common` (default = `common`).
- Modularizada la skill `trello-api-client` (SKILL.md de 616 a <100 lineas; detalle en `references/`).
- Author propio normalizado a `Felipe Pérez` en las skills propias.

### Aniadido

- Skills incorporadas al repo: `find-skills` y `mcp-builder` (common), `infisical-admin-mcp` (copilot-only).
- `scripts/install-opencode-config.mjs`: instala la config gestionada de OpenCode (json-merge + bloque markdown).
- Guardia anti-NAS `skills_hub_assert_local` en `scripts/lib/common.sh`.
- `scripts/doctor.sh` para diagnostico rapido de entorno local.
- Baseline de estandares de repositorio con `.editorconfig`, `.gitattributes` y `LICENSE`.
- Workflow de release por tags en `.github/workflows/release.yml`.
- Politica versionada de branch protection en `.github/branch-protection.main.json`.
- Script `scripts/setup-branch-protection.sh` para aplicar branch protection con GitHub CLI.
- Guia operativa en `BRANCH_PROTECTION.md`.

### Eliminado

- Motor de symlinks `scripts/link-skills.mjs` y `scripts/lib/link-skills-*.mjs`. La logica de config gestionada de OpenCode se traslado a `scripts/install-opencode-config.mjs`.
- Skill duplicada `mente-docs` (clon al 75% de `atlas-docs` con naming obsoleto `mente`; `atlas-docs` es la canonica).

## [1.1.0] - 2026-05-17

Release publicado en GitHub. El detalle de cambios no se registro en este
changelog en su momento; ver
<https://github.com/FelipePepe/skills-hub/releases/tag/v1.1.0>.

## [0.1.0] - 2026-04-13

### Aniadido

- Archivo de instrucciones globales para agentes en `.github/copilot-instructions.md`.
- Guia de contribucion en `CONTRIBUTING.md`.
- Plantilla de pull request en `.github/pull_request_template.md`.
- Plantillas de issue para bug y feature request en `.github/ISSUE_TEMPLATE/`.
- Workflow de calidad en GitHub Actions en `.github/workflows/quality.yml`.
- Script `scripts/lint.sh` para validar sintaxis Bash y formato de `SYNC_PAIRS`.

### Cambiado

- `README.md` ahora incluye flujo profesional recomendado y seccion de calidad automatizada.

[Sin publicar]: https://github.com/FelipePepe/skills-hub/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/FelipePepe/skills-hub/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/FelipePepe/skills-hub/releases/tag/v1.1.0
[0.1.0]: https://github.com/FelipePepe/skills-hub/releases/tag/v0.1.0
