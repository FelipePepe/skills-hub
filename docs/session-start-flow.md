# Flujo completo — session-start + SDD

1. **Arranque**: el agente lee el proyecto en este orden: CBM (codebase-memory) → documentación del proyecto → engram.
2. **Pregunta**: con esa información, pregunta al usuario qué hacer en el proyecto.
3. **Respuesta escueta**: si la respuesta es corta/vaga, el agente pide explícitamente que sea más explícito (no se invoca `enrich-us`).
4. **Respuesta explícita**: cuando la información es suficiente y el agente entiende la tarea, la documenta en `docs/`, en una subcarpeta específica para esa feature/hotfix, aplicando `cognitive-doc-design` para que la documentación reduzca la carga cognitiva.
5. **Chequeo de cumplimiento**: si la feature toca datos personales o el dominio es regulado, se aplican `eu-gdpr` y `compliance-ops` antes de continuar.
6. **Chequeo de arquitectura**: si no existe una especificación detallada de arquitectura/diseño de la aplicación, se ejecuta primero una fase de exploración/diseño arquitectónico que la genere, antes de continuar.
7. **SDD (openspec)**: se lanza la nueva versión de openspec para generar los documentos detallados a partir de esa documentación (y de la arquitectura/cumplimiento, si se generaron en los pasos anteriores).
8. **Tareas**: la fase de tareas define un checklist con el máximo detalle posible; cada ítem se marca completado solo cuando está implementado y sus tests han pasado. `work-unit-commits` planifica cómo se trocean esas tareas en commits/PRs revisables.
9. **TDD obligatorio**: toda implementación sigue red → green → refactor, siempre, sin excepción.
10. **Tests e2e**: se añaden tests e2e que cubren detalladamente todos los casos de uso, tanto normales como extremos. Los tests e2e web se implementan con Playwright, documentando captura de pantalla de cada test e2e realizado.
11. **Implementación**: se ejecuta mediante subagentes, cada uno con el contexto mínimo necesario para su tarea. Se usa `run` para lanzar la app y confirmar que la feature funciona de verdad.
12. **Verificación**: se ejecutan las skills `code-reviewer`, `judgment-day`, `security-review` y `silent-failure-hunter` usando un modelo LLM distinto al usado en la implementación, para obtener un segundo punto de vista independiente.
13. **GitFlow**: el commit, merge y creación de PR de la feature/hotfix sigue la skill `gitflow` (rama, commit convencional, PR), respetando la planificación de `work-unit-commits`.
14. **Trazabilidad IA**: todas las acciones realizadas por los agentes quedan reflejadas en un documento siguiendo la Ley Europea de IA (EU AI Act).
15. **Session-end**: al cerrar la sesión se actualiza la documentación de la aplicación (`cognitive-doc-design`), se documentan en la carpeta de la feature todas las tareas realizadas y todos los tests (incluidos los e2e con sus capturas de pantalla), y se reindexa `skill-registry` si la feature creó o modificó una skill.
