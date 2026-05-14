# skills-hub

Fuente unica de verdad para skills y tooling de sincronizacion.

Incluye una CLI instalable para exponer el catalogo en las apps locales compatibles.

## Objetivo

Mantener contenido versionado en un solo repositorio y exponerlo hacia apps instaladas mediante enlaces simbolicos o junctions:

- ~/.copilot/skills
- ~/.claude/skills
- ~/.config/Code/User/prompts

## Estado actual

- `skills/copilot-only` es la fuente principal para las skills activas de Copilot/OpenCode.
- `skills/common` queda reservado para skills realmente portables entre plataformas.
- `skills/claude-only` queda reservado para variantes especificas de Claude.
- `~/.agents/skills` no se sincroniza automaticamente por ahora para evitar sobreescribir skills locales no modeladas aun en este repo.
- `prompts`, `config` y `scripts` permanecen en el repo porque forman parte del tooling de sincronizacion y validacion.
- `scripts/link-skills.mjs` es el instalador cross-platform recomendado para Linux y Windows.
- `opencode/` contiene configuracion gestionada para OpenCode que se fusiona sin machacar la config local.

## Estructura

- `skills/common`: contenido compartido entre plataformas.
- `skills/copilot-only`: contenido exclusivo para Copilot.
- `skills/claude-only`: contenido exclusivo para Claude.
- `prompts`: prompts globales e instrucciones.
- `config/apps.json`: manifiesto de apps detectables e instalables.
- `config/sync-map.sh`: mapeos legacy para contenido copiable como `prompts`.
- `opencode/opencode.managed.json`: fragmento gestionado de `opencode.json`.
- `opencode/AGENTS.md`: bloque gestionado para `.opencode/AGENTS.md`.
- `scripts/import-copilot-skills.sh`: bootstrap para importar skills locales existentes al repo.
- `bin/skills-hub.js`: CLI instalable del repo.
- `scripts/link-skills.mjs`: detecta apps instaladas y crea symlinks/junctions por skill.
- `scripts/sync.sh`: ejecuta el instalador por enlaces y sincroniza contenido legacy copiable.
- `scripts/check.sh`: valida el plan de instalacion por enlaces y el drift del contenido legacy.

## Uso rapido

```bash
pnpm install
pnpm skills-hub status
pnpm skills-hub install --dry-run
pnpm skills-hub install
./scripts/import-copilot-skills.sh --dry-run
./scripts/import-copilot-skills.sh
./scripts/doctor-skills.sh
./scripts/doctor.sh
./scripts/lint.sh
node ./scripts/link-skills.mjs status
node ./scripts/link-skills.mjs install --dry-run
node ./scripts/link-skills.mjs install
./scripts/sync.sh --dry-run
./scripts/sync.sh
./scripts/check.sh
```

## Flujo profesional recomendado

- Lee la guia de contribucion: `CONTRIBUTING.md`
- Valida cambios locales antes de abrir PR:

```bash
./scripts/doctor-skills.sh
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

- Usa templates de issue y pull request en `.github/`.

## CLI de instalacion

La app/CLI oficial del repo es `skills-hub`.

Comandos:

```bash
pnpm skills-hub status
pnpm skills-hub install
pnpm skills-hub install --dry-run
pnpm skills-hub install --app=copilot
pnpm skills-hub install --replace
pnpm skills-hub doctor
pnpm skills-hub doctor-skills
pnpm skills-hub lint
pnpm skills-hub check
```

Notas:

- reutiliza la misma logica que `scripts/link-skills.mjs`
- sirve como entrypoint formal para instalar las skills
- respeta `config/apps.json` como fuente de exposicion por plataforma
- sigue un modelo de CLI de producto parecido a `gentle-ai`, pero centrado en este catalogo
- usa `pnpm skills-hub ...` dentro del repo; `pnpm exec` no expone el binario del paquete raiz

## Calidad automatizada

- CI ejecuta `./scripts/lint.sh` en cada push y pull request.
- El objetivo de CI es validar scripts y convenciones del repo sin depender de destinos locales.
- `./scripts/validate-skills.sh` valida reglas semanticas basicas del catalogo: limite de 300 lineas por `SKILL.md`, naming no obsoleto y referencias legacy controladas.
- `./scripts/doctor-skills.sh` audita el catalogo canonico: alineacion carpeta/frontmatter, fuentes expuestas por app y colisiones de nombre por plataforma.

## Fuente canonica y modelo de exposicion

Este repo es la **fuente canonica** de authoring:

- `skills/` contiene las skills reales
- `config/apps.json` define que carpetas fuente expone cada app
- `config/sync-map.sh` mantiene solo contenido legacy copiable

Las rutas locales de apps (`~/.copilot/skills`, `~/.claude/skills`, `~/.agents/skills`, OpenCode) son **targets de exposicion**, no sitios de mantenimiento manual.

Reglas:

- un nombre de skill canonico por directorio
- carpeta y frontmatter `name` deben coincidir
- no duplicar el mismo nombre de skill dentro del conjunto expuesto a una misma app
- tras renames, actualizar tambien prompts, config gestionada y referencias

## Convencion global de package manager

Para proyectos JavaScript/TypeScript, la convención por defecto del catálogo es:

- usar `pnpm` como package manager recomendado
- evitar ejemplos nuevos con `npm` salvo que la skill documente compatibilidad heredada o tooling externo
- reflejar la política de seguridad de dependencias cuando una skill cubra bootstrap o setup de proyecto

Política recomendada:

```yaml
minimumReleaseAge: 10080
minimumReleaseAgeStrict: true
minimumReleaseAgeIgnoreMissingTime: false
```

Excepciones:

- si un repo ya declara otro package manager, la skill debe respetar el repo y explicitarlo
- ejemplos con `npm` solo son válidos si el contexto depende de tooling o fixtures externos que aún lo requieran

## Criterio de clasificacion

- Si una skill depende de un workflow o plataforma concreta de Copilot/OpenCode, va a `skills/copilot-only`.
- Si una skill no depende de Copilot y puede compartirse sin cambios, puede promocionarse despues a `skills/common`.
- No mezclar configuracion de maquina dentro de `skills/`; eso debe quedarse en el tooling o fuera del repo.

## Instalacion por enlaces

El flujo recomendado es instalar skills mediante enlaces por skill, no copiando directorios completos:

- En Linux se crean symlinks.
- En Windows se crean junctions para directorios.
- El instalador detecta si existen `~/.copilot`, `~/.claude` o sus equivalentes en `%USERPROFILE%`.
- Para OpenCode, el instalador fusiona `opencode.json` y actualiza un bloque gestionado dentro de `.opencode/AGENTS.md`.
- Si una app no esta instalada, se omite por defecto.
- Si una ruta ya existe y no es un enlace del repo, se respeta y se marca como `skip`.
- Antes de modificar ficheros de configuracion, crea backups `.bak-YYYYMMDD-HHMMSS`.

Comandos:

```bash
node ./scripts/link-skills.mjs status
node ./scripts/link-skills.mjs install --dry-run
node ./scripts/link-skills.mjs install
node ./scripts/link-skills.mjs install --app=copilot
node ./scripts/link-skills.mjs install --replace
```

Flags:

- `--app=<id>` limita a una app concreta
- `--dry-run` muestra el plan sin tocar disco
- `--replace` reemplaza enlaces existentes que apunten a otra ruta
- `--include-missing` crea la ruta destino aunque la app no se detecte

## Contenido legacy copiable

No todo requiere enlaces. `prompts/` sigue tratandose como contenido copiable y se sincroniza con `rsync`.
Por eso `sync.sh` mantiene un paso legacy adicional despues de la instalacion por enlaces.

## Historial de cambios

- Ver `CHANGELOG.md` para cambios notables del proyecto.
- Ver `RELEASING.md` para el proceso de versionado y publicacion.

## Gobernanza y seguridad

- Ver `CONTRIBUTING.md` para flujo de contribucion.
- Ver `SECURITY.md` para reporte responsable de vulnerabilidades.
- Ver `.github/CODEOWNERS` para propiedad de revision por rutas.
- Ver `BRANCH_PROTECTION.md` para enforcement de checks en `main`.
