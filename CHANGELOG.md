# Changelog

Todos los cambios notables de este proyecto se documentaran en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

### Aniadido

- `scripts/doctor.sh` para diagnostico rapido de entorno local.
- Baseline de estandares de repositorio con `.editorconfig`, `.gitattributes` y `LICENSE`.
- Workflow de release por tags en `.github/workflows/release.yml`.
- Politica versionada de branch protection en `.github/branch-protection.main.json`.
- Script `scripts/setup-branch-protection.sh` para aplicar branch protection con GitHub CLI.
- Guia operativa en `BRANCH_PROTECTION.md`.

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

[Sin publicar]: https://github.com/<org>/<repo>/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/<org>/<repo>/releases/tag/v0.1.0
