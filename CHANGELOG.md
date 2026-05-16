# Changelog

Todos los cambios notables de este proyecto se documentaran en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

### Aniadido

#### Sistema harness-agnostico con los 20 Gentli Harnesses

- `skills/common/sdd/SKILL.md` — orchestrador SDD completo con harnesses #1 #2 #4 #6 #7 #8 #14 #15 #16 #17 #21 embebidos.
- `skills/common/memory/SKILL.md` — harness #10: backend-agnostic con soporte Engram, fallback filesystem y protocolo cross-agent.
- `skills/common/review-warlock/SKILL.md` — harness #18: evaluacion de riesgo de entrega antes de `sdd-apply`; invocado por `sdd-tasks`.
- `skills/common/delivery-strategy/SKILL.md` — harnesses #19 #20 #26: estrategia de entrega, chain strategy y rollback.
- `skills/common/session-start/SKILL.md` — protocolo de inicio de sesion reescrito: harness-agnostico, 4 pasos (memoria, branch, SDD state, resumen).
- `skills/common/atlas-docs/SKILL.md` — skill de documentacion en vault Obsidian movida a `common/` y marcada harness-agnostica.

#### Fases SDD migradas a common/ con mejoras

- `skills/common/sdd-init/` — harness #3 "Calibration Before Code" añadido; `harness: agnostic`.
- `skills/common/sdd-explore/`, `sdd-propose/`, `sdd-spec/`, `sdd-design/`, `sdd-archive/` — migradas con `harness: agnostic`.
- `skills/common/sdd-tasks/SKILL.md` — Step 5 de estimacion de riesgo de entrega (harness #18) añadido al return envelope.
- `skills/common/sdd-apply/SKILL.md` — harness #13 Apply Progress Continuity: Step 0 lee `apply-progress` y reanuda desde la primera tarea pendiente. Nunca re-implementa tareas completadas.
- `skills/common/sdd-verify/SKILL.md` — harness #12 "Evidence, Not Belief": cabecera añadida reforzando que solo un test que PASA es evidencia.
- `skills/common/sdd-archive/SKILL.md` — dos pasos nuevos: Step 5 Knowledge Distillation (guarda `sdd/{change}/knowledge` en Engram, obligatorio en cualquier modo) y Step 6 Doc Backend (publica nota de proyecto en Atlas/Notion si `doc_backend` esta configurado).

#### Skills genericas migradas a common/

- `branch-pr/`, `code-reviewer/`, `db-architect/`, `judgment-day/`, `red-team-offensive/`, `skill-creator/`, `test-runner/` — migradas con `harness: agnostic`.

#### Adaptador Pi (`skills/adapters/pi/`)

- `memory.ts` — extension Pi que inyecta contexto Engram en `before_agent_start` y guarda resumen de sesion en `settled`. Fallback a filesystem (`~/.memory/MEMORY.md`). Comandos: `/memory-context`, `/memory-save`.
- `skill-resolver.ts` — extension Pi que lee el skill registry desde Engram o `.atl/skill-registry.md`, extrae `## Compact Rules` y los pre-inyecta en el system prompt. Auto-recarga si detecta `skill_resolution: fallback-*`. Comandos: `/skill-rules`, `/skill-reload`.
- `session-guard.ts` — extension Pi que intercepta 30+ patrones de comandos destructivos (`rm -rf`, `git reset --hard`, `DROP TABLE`, force push, `dd`, etc.) y bloquea hasta confirmacion del usuario. Comandos: `/guard-on`, `/guard-off`, `/guard-status`.
- `package.json` — manifest Pi con `pi.extensions` declarando los tres entry points, hooks y comandos.

#### Adaptadores OpenCode y Claude

- `skills/adapters/opencode/README.md` — guia de configuracion: MCP para Engram, mapeo de sub-agentes, model routing JSON.
- `skills/adapters/claude/README.md` — guia de hooks, `settings.json` y skill registry auto-refresh.

#### Contratos compartidos (`skills/common/_shared/`)

- `harness-adapter-contract.md` — define la interfaz que cada harness debe implementar: sub-agent isolation, memory backend, filesystem, skill discovery, model routing, hooks opcionales.
- `engram-convention.md`, `openspec-convention.md`, `persistence-contract.md`, `sdd-phase-common.md`, `skill-resolver.md` — copiados desde copilot-only para disponibilidad cross-harness.

#### Config

- `config/apps.json` — Pi añadido como target de instalacion con `sources: [skills/common]` y `adapterPath: skills/adapters/pi`.
- `config/apps.json` — `adapterSources` añadido mapeando pi/opencode/claude a sus rutas de adaptador.

### Cambiado

- `README.md` — seccion "Estado actual" actualizada para reflejar que `skills/common` es la fuente principal (37+ skills). Arquitectura de harnesses documentada. Criterio de clasificacion extendido con la capa `adapters/`.
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

[Sin publicar]: https://github.com/FelipePepe/skills-hub/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/FelipePepe/skills-hub/releases/tag/v0.1.0
