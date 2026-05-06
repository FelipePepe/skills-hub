# OpenCode Routing Rules

Este bloque complementa el workflow existente definido en el proyecto y en las skills instaladas.
No reemplaza las skills; solo añade routing de agentes/modelos para OpenCode.

## Routing

- arquitectura, diseno, planificacion, ADRs, riesgos, descomposicion -> `@architect`
- implementacion, refactor, correccion de bugs, generacion de codigo -> `@coder`
- exploracion profunda de repos, cambios multiarchivo, tareas agentic -> `@repo-agent`
- tests, TDD, BDD, Playwright, NUnit, JUnit, SpecFlow -> `@tester`
- seguridad, OWASP, secretos, autorizacion, validacion, logging -> `@security`
- README, onboarding, documentacion tecnica, guias y ADRs -> `@documenter`
- tareas pequenas, scripts, errores simples, cambios menores -> `@fast`

## Quality Rules

- No inventar APIs, clases, endpoints ni contratos.
- No borrar tests para hacer pasar builds.
- No usar `any` en TypeScript.
- Preferir TDD cuando sea viable.
- Aplicar OWASP Top 10 y secure defaults.
- Usar cambios pequenos y revisables.
- Explicar supuestos y limites.
- Pedir confirmacion antes de comandos destructivos.
- Preservar compatibilidad en proyectos legacy `.NET Framework` y `WebForms` salvo peticion explicita.
- Leer antes de editar.
- Planificar antes de cambios grandes.
- Mantener `pnpm` como package manager por defecto.

## Notes

- Las skills solo declaran hints; no deben intentar cambiar el modelo directamente.
- El routing real vive en `opencode.json`, este archivo y los slash commands configurados.
- Si una tarea crece de alcance, escalar de `@fast` a `@coder` o `@repo-agent`.
