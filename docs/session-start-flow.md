# Flujo completo — session-start + SDD

1. **Arranque** (`session-start`): el agente lee el proyecto en este orden: CBM (codebase-memory) → documentación del proyecto → engram.
2. **Pregunta**: con esa información, pregunta al usuario qué hacer en el proyecto.
3. **Respuesta escueta**: si la respuesta es corta/vaga, el agente pide explícitamente que sea más explícito (no se invoca `enrich-us`).
4. **Respuesta explícita**: cuando la información es suficiente y el agente entiende la tarea, la documenta en `docs/`, en una subcarpeta específica para esa feature/hotfix, aplicando `cognitive-doc-design` para que la documentación reduzca la carga cognitiva.
5. **Chequeo de cumplimiento**: si la feature toca datos personales o el dominio es regulado, se aplican `eu-gdpr` y `compliance-ops` antes de continuar.
6. **Chequeo de arquitectura**: si no existe una especificación detallada de arquitectura/diseño de la aplicación, se ejecuta `/opsx:explore` primero para generarla.
7. **`sdd init`**: `sdd-init` bootstrapea el CLI real de OpenSpec (`@fission-ai/openspec`, ≥1.6, `pnpm dlx @fission-ai/openspec@latest init --tools all --force`), bifurca el schema para añadir un artefacto `verify` propio, rellena `openspec/config.yaml` (contexto, reglas de TDD/verify/archive), construye `.atl/skill-registry.md` y registra el proyecto en Engram (memoria de empresa).
8. **`sdd new <change>`**: `/opsx:propose "<change>"` genera proposal → specs → design → tasks en un único pipeline real (el CLI real de OpenSpec, no sub-agentes propios). `work-unit-commits` planifica cómo se trocean las tareas resultantes en commits/PRs revisables.
9. **TDD obligatorio**: toda implementación sigue red → green → refactor, siempre, sin excepción — sin flag de configuración que lo desactive.
10. **Tests e2e**: cubren detalladamente todos los casos de uso, normales y extremos. Los tests e2e web se implementan con Playwright, documentando captura de pantalla de cada test realizado.
11. **`sdd apply`**: `/opsx:apply` implementa las tareas vía subagentes con el contexto mínimo necesario. Se usa `run` para lanzar la app y confirmar que la feature funciona de verdad.
12. **`sdd verify`**: gate de calidad en dos capas —
    - `sdd-verify` (skill propia, sin equivalente en el CLI): ejecuta tests + build + e2e Playwright (con capturas) + matriz de cumplimiento de specs + evidencia de TDD estricto.
    - Segunda opinión independiente, en un **modelo LLM distinto** al usado en `sdd apply`: `red-team-offensive`, `code-reviewer`, `judgment-day`, `security-review`, `silent-failure-hunter`.
    - Cualquier CRITICAL de cualquiera de las anteriores bloquea el archive.
13. **`sdd archive`**: `/opsx:archive` (merge de delta specs en las specs principales + mover el change a `openspec/changes/archive/`).
14. **GitFlow**: el commit, merge y creación de PR de la feature/hotfix sigue la skill `gitflow` (rama, commit convencional, PR), respetando la planificación de `work-unit-commits`.
15. **Trazabilidad IA**: todas las acciones realizadas por los agentes quedan reflejadas en un documento siguiendo la Ley Europea de IA (EU AI Act).
16. **Memoria de empresa (Engram)**: en cada transición de fase (init/new/apply/verify/archive) se guarda una observación compacta en Engram — aditiva a `openspec/`, nunca lo sustituye, nunca bloquea el ciclo si Engram no está disponible.
17. **Session-end**: al cerrar la sesión se actualiza la documentación de la aplicación (`cognitive-doc-design`), se documentan en la carpeta de la feature todas las tareas realizadas y todos los tests (incluidos los e2e con sus capturas de pantalla), y se reindexa `skill-registry` si la feature creó o modificó una skill.

## Skills SDD propias restantes

Solo quedan como skills bespoke: `sdd` (orquestador), `sdd-init`, `sdd-verify` y `sdd-onboard`. El resto del ciclo (`propose`/`spec`/`design`/`tasks`/`apply`/`archive`/`explore`) corre vía `/opsx:*` del CLI real de OpenSpec, instalado para todos los editores soportados (`--tools all`, incluye Copilot/VS Code).
