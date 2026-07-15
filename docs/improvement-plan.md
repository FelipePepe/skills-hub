# Plan de mejora de skills-hub

## Objetivo

Mejorar `skills-hub` sin cambiar su identidad: debe seguir siendo la fuente
canónica local y versionada de skills, con instalación por copia hacia apps de
IA. Las mejoras deben aumentar descubribilidad, seguridad de instalación,
trazabilidad y soporte multi-agente sin convertir el proyecto en un configurador
completo como Gentle AI.

## Principios de diseño

- Mantener `skills/` como fuente de verdad de authoring.
- Mantener destinos locales como copias, nunca como fuente editable.
- No introducir symlinks ni dependencias de NAS.
- Preferir manifiestos declarativos sobre lógica dispersa en scripts.
- Añadir salidas legibles por máquina donde ayuden a validar o automatizar.
- Conservar el flujo simple actual: `install`, `status`, `check`, `doctor`,
  `lint`.

## Fase 1: Registro index-first de skills

### Problema

Los agentes necesitan elegir skills relevantes, pero `skills-hub` hoy distribuye
el catálogo sin producir un índice explícito para delegadores o subagentes. Esto
obliga a leer demasiado contenido o a depender de instrucciones globales.

### Resultado esperado

Un comando `skills-hub registry refresh` genera un índice local con nombre,
descripción, scope, plataforma expuesta y ruta exacta de cada `SKILL.md`. El
índice no resume reglas: solo apunta al archivo fuente para que el agente lea la
skill completa cuando corresponda.

### Tareas

1. Añadir comando `registry` a `bin/skills-hub.js`.
2. Crear script o módulo `scripts/registry-refresh.*` que:
   - escanee `skills/common`, `skills/claude-only`, `skills/copilot-only`;
   - ignore `_shared` y referencias internas;
   - lea frontmatter `name` y `description`;
   - use el nombre de carpeta como fallback controlado;
   - detecte colisiones por app expuesta según `config/apps.json`.
3. Generar un archivo de índice, por ejemplo `generated/skill-registry.md` o
   `.skills-hub/skill-registry.md`.
4. Añadir modo no destructivo:
   - `skills-hub registry list`
   - `skills-hub registry list --json`
5. Integrar la validación en `doctor-skills` o `lint`.
6. Documentar el contrato: el índice contiene rutas y descripciones, no reglas
   compactadas.

### Validación

- `pnpm skills-hub registry list`
- `pnpm skills-hub registry refresh`
- `pnpm skills-hub doctor-skills`
- `pnpm skills-hub lint`

## Fase 2: Plan de instalación estructurado

### Problema

`install --dry-run` muestra intención, pero no deja un plan estructurado que
pueda auditarse, compararse en CI o reutilizarse por otros agentes.

### Resultado esperado

`skills-hub install --dry-run --json` emite un plan con apps detectadas,
fuentes, destinos, operaciones de copia, archivos de configuración gestionados y
advertencias.

### Tareas

1. Definir un esquema mínimo de plan:
   - `appId`
   - `detected`
   - `source`
   - `target`
   - `operation`
   - `strategy`
   - `warnings`
2. Separar resolución de plan y ejecución real en el script de instalación.
3. Añadir `--json` a `install`, `sync` y `status`.
4. Hacer que `doctor` pueda reutilizar el mismo resolvedor de apps.
5. Añadir tests de snapshot o fixtures para planes esperados.

### Validación

- `pnpm skills-hub install --dry-run`
- `pnpm skills-hub install --dry-run --json`
- `pnpm skills-hub status --json`
- `pnpm skills-hub check`

## Fase 3: Backups antes de escribir

### Problema

La política de copia reduce riesgo, pero una sincronización todavía puede
sobrescribir configuración local gestionada por otras herramientas.

### Resultado esperado

Antes de aplicar cambios, `skills-hub` crea un snapshot local de archivos y
directorios que va a modificar. El snapshot debe poder listarse y restaurarse.

### Tareas

1. Crear directorio local de backups, por ejemplo `~/.local/share/skills-hub/backups`.
2. Guardar manifiesto por snapshot:
   - id;
   - fecha;
   - app;
   - rutas afectadas;
   - checksums cuando sea barato;
   - versión de `skills-hub`.
3. Añadir comandos:
   - `skills-hub backups list`
   - `skills-hub backups restore <id>`
   - `skills-hub backups prune`
4. Crear backup solo para rutas que serán escritas.
5. Mantener retención simple: conservar los últimos 5 snapshots por defecto.
6. Documentar que los backups son locales y no se versionan en Git.

### Validación

- `pnpm skills-hub install --dry-run`
- `pnpm skills-hub install`
- `pnpm skills-hub backups list`
- restauración manual en fixture temporal

## Fase 4: Modelo de targets multi-agente

### Problema

`config/apps.json` ya es un buen manifiesto, pero todavía mezcla apps, sources,
config files y algunos casos de agents. Esto puede crecer mal al añadir Codex,
Cursor, Gemini, Qwen, Kiro, Windsurf u OpenCode ampliado.

### Resultado esperado

Un modelo declarativo más explícito para targets: skills, agents, behavior,
config merge y hooks/startup si aplica.

### Tareas

1. Extender `config/apps.json` o dividirlo en `config/targets/*.json`.
2. Añadir campos normalizados:
   - `id`
   - `kind`
   - `detectPaths`
   - `skillSources`
   - `agentSources`
   - `behaviorFiles`
   - `managedConfig`
   - `supportsRegistry`
3. Migrar las entradas actuales sin cambiar comportamiento.
4. Añadir validación de manifiesto en `lint`.
5. Añadir targets gradualmente:
   - Codex;
   - Cursor;
   - OpenCode skills/config extendido;
   - generic agents.

### Validación

- `pnpm skills-hub lint`
- `pnpm skills-hub doctor`
- `pnpm skills-hub install --dry-run --app=<id>`

## Fase 5: Doctor unificado y mensajes accionables

### Problema

Hay varios comandos de validación útiles, pero el usuario necesita una lectura
única de salud: catálogo, destinos, drift, manifiestos y permisos.

### Resultado esperado

`skills-hub doctor` muestra un resumen compacto y accionable, y `--json` da una
salida estable para CI o agentes.

### Tareas

1. Unificar resultados de:
   - detección de apps;
   - auditoría de catálogo;
   - drift;
   - validez de manifiestos;
   - estado del registry.
2. Clasificar hallazgos:
   - `error`;
   - `warning`;
   - `info`.
3. Añadir sugerencias de reparación cuando sean seguras.
4. Evitar reparación automática por defecto.
5. Añadir `skills-hub doctor --fix` solo para acciones reversibles y respaldadas
   por backup.

### Validación

- `pnpm skills-hub doctor`
- `pnpm skills-hub doctor --json`
- `pnpm skills-hub lint`

## Fase 6: Gobernanza del catálogo

### Problema

El catálogo crece y necesita reglas más visibles para evitar skills demasiado
largas, duplicadas, mezcladas con configuración de máquina o acopladas a una
plataforma sin necesidad.

### Resultado esperado

Un conjunto de reglas de authoring y validación que mantenga las skills
portables, token-efficient y seguras.

### Tareas

1. Actualizar `docs/skills-governance.md` con:
   - criterio para `common` vs `*-only`;
   - límites de tamaño;
   - uso de `references/`;
   - reglas de frontmatter;
   - prohibición de secretos.
2. Hacer que `doctor-skills` reporte:
   - frontmatter faltante;
   - descripción débil;
   - referencias rotas;
   - nombres no canónicos;
   - colisiones por app expuesta.
3. Añadir fixtures para skills válidas e inválidas.
4. Mantener errores bloqueantes solo para problemas que rompen instalación o
   seguridad; usar warnings para mejoras editoriales.

### Validación

- `pnpm skills-hub doctor-skills`
- `pnpm skills-hub lint`

## Orden recomendado de implementación

1. Fase 1: registry index-first.
2. Fase 2: plan estructurado de instalación.
3. Fase 5: doctor unificado usando el plan y el registry.
4. Fase 3: backups antes de escrituras.
5. Fase 4: modelo de targets multi-agente.
6. Fase 6: gobernanza ampliada del catálogo.

## Criterios de aceptación globales

- `pnpm skills-hub install --dry-run` sigue funcionando.
- `pnpm skills-hub install` sigue copiando, no enlazando.
- `pnpm skills-hub check` sigue detectando drift.
- `pnpm skills-hub lint` valida los nuevos manifiestos y registry.
- Ningún comando escribe fuera de destinos declarados.
- Ningún comando requiere NAS ni rutas absolutas de usuario.
- Las mejoras son compatibles con el principio: repo canónico en GitHub, copias
  locales en cada app.

## Riesgos y mitigaciones

- Riesgo: duplicar lógica entre scripts shell y CLI Node.
  Mitigación: extraer resolución de apps/planes a un solo módulo reutilizable.
- Riesgo: el registry se use como resumen de reglas.
  Mitigación: documentar y validar que el índice solo apunta a `SKILL.md`.
- Riesgo: backups aumenten complejidad del instalador.
  Mitigación: empezar con snapshots simples antes de compresión/deduplicación.
- Riesgo: añadir demasiados targets de golpe.
  Mitigación: migrar manifiesto primero, añadir targets uno por uno con dry-run.

## No objetivos

- Reescribir `skills-hub` como Gentle AI.
- Añadir TUI.
- Añadir SDD, Engram, MCP o gestión de modelos dentro de `skills-hub`.
- Cambiar el modelo de copia por symlinks.
- Convertir copias instaladas en fuentes editables.
