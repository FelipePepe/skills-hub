# Changelog

Todos los cambios notables de este proyecto se documentaran en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

### Cambiado

- Modelo de instalacion: las skills ahora se **copian** (rsync) a cada app en `scripts/sync.sh`, en lugar de exponerse por symlink. Quedan en disco local de la maquina e independientes del clon.
- Invariante de localidad: `scripts/lib/common.sh` incorpora `skills_hub_assert_local`, que aborta si el clon o algun destino vive en un filesystem de red (NFS/CIFS/SMB/sshfs). Aplicado en `sync.sh`, `check.sh` y `doctor.sh`.
- `check.sh` detecta drift comparando contenido repo<->copias (rsync -ani) y marca symlinks residuales como drift.
- `bin/skills-hub.js`: `install`/`sync` ejecutan `sync.sh`; `status` reutiliza la deteccion de `doctor.sh`.
- Reclasificacion del catalogo: el grupo SDD y las skills base de Claude se movieron de `copilot-only` a `common` (default = `common`).
- Modularizada la skill `trello-api-client` (SKILL.md de 616 a <100 lineas; detalle en `references/`).

### Eliminado

- Motor de symlinks `scripts/link-skills.mjs` y `scripts/lib/link-skills-*.mjs`. La logica de config gestionada de OpenCode se traslado a `scripts/install-opencode-config.mjs`.

### Aniadido

- `scripts/doctor.sh` para diagnostico rapido de entorno local.
- Baseline de estandares de repositorio con `.editorconfig`, `.gitattributes` y `LICENSE`.
- Workflow de release por tags en `.github/workflows/release.yml`.
- Politica versionada de branch protection en `.github/branch-protection.main.json`.
- Script `scripts/setup-branch-protection.sh` para aplicar branch protection con GitHub CLI.
- Guia operativa en `BRANCH_PROTECTION.md`.
- Skill `sdd-doc` — nueva fase del pipeline SDD para generar docs faltantes (C4, ADRs, API funcional, tech arch).
- Delta tracking en `sdd-apply` — cada task genera un snapshot `.diff` para HyperFrames video.

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

[Sin publicar]: https://github.com/FelipePepe/skills-hub/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/FelipePepe/skills-hub/releases/tag/v0.1.0
