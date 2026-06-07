# skills-hub

Fuente única de verdad para tus skills y agents de asistentes de IA, pensada para **instalarlas en cualquiera de tus máquinas** desde un único repositorio en GitHub.

Incluye una CLI instalable que copia el catálogo a las apps locales compatibles.

## Objetivo

Mantener todas las skills versionadas en un solo repositorio y **distribuirlas a varias máquinas**: clonas el repo en disco local de cada equipo y copias las skills a los directorios de cada app.

- ~/.copilot/skills
- ~/.claude/skills
- ~/.agents/skills
- ~/.claude/agents
- ~/.agents/agents
- ~/.config/Code/User/prompts (contenido legacy)
- OpenCode (config gestionada)

### Principios

- **Fuente única en GitHub.** El repo es la verdad; cada máquina lo clona.
- **Todo local, sin NAS.** Ni el clon ni los destinos pueden vivir en un filesystem de red. Los scripts abortan si detectan NFS/CIFS/SMB/sshfs.
- **Copia, no symlinks.** Las skills se copian a cada app, de modo que quedan dentro de la máquina e independientes del clon. Tras editar una skill, re-ejecuta `sync` para propagar.

## Estructura

- `skills/common`: skills compartidas por todas las plataformas (el caso por defecto).
- `skills/copilot-only`: skills exclusivas de Copilot/OpenCode (excepción).
- `skills/claude-only`: skills exclusivas de Claude (excepción).
- `agents/common`: agents ligeros compartidos que enrutan trabajo hacia skills.
- `agents/claude-only`, `agents/codex-only`, `agents/opencode-only`: agents específicos de plataforma cuando sean necesarios.
- `prompts`: prompts globales e instrucciones (contenido copiable legacy).
- `config/apps.json`: manifiesto de apps detectables, sus rutas y qué fuentes de skills/agents consume cada una.
- `manifests/`: módulos, componentes y perfiles instalables al estilo ECC para planificación selectiva.
- `config/sync-map.sh`: mapeos legacy para contenido copiable como `prompts`.
- `opencode/opencode.managed.json`: fragmento gestionado de `opencode.json` (json-merge).
- `opencode/AGENTS.md`: bloque gestionado para `.opencode/AGENTS.md`.
- `bin/skills-hub.js`: CLI instalable del repo.
- `scripts/sync.sh`: instalador por **copia** (rsync) + config gestionada de OpenCode.
- `scripts/install-opencode-config.mjs`: instala la config gestionada de OpenCode (merge).
- `scripts/check.sh`: detecta drift entre el repo y las copias instaladas.
- `scripts/import-copilot-skills.sh`: bootstrap para importar skills locales existentes al repo.

## Uso rápido

```bash
pnpm install
pnpm skills-hub status            # apps detectadas + auditoría del catálogo
pnpm skills-hub install --dry-run # plan de copia sin tocar disco
pnpm skills-hub plan --list-profiles # perfiles declarativos disponibles
pnpm skills-hub install           # copia skills y agents a las apps locales
pnpm skills-hub check             # ¿hay drift entre repo y copias?
```

Equivalentes directos:

```bash
./scripts/sync.sh --dry-run
./scripts/sync.sh
./scripts/sync.sh --app=claude
./scripts/check.sh
./scripts/doctor.sh
./scripts/doctor-skills.sh
./scripts/doctor-agents.sh
node ./scripts/validate-manifests.mjs
./scripts/lint.sh
./scripts/import-copilot-skills.sh --dry-run
```

## Instalación en una máquina nueva

```bash
git clone <repo> ~/sources/skills-hub   # en disco LOCAL, nunca en un NAS
cd ~/sources/skills-hub
pnpm install
pnpm skills-hub install
```

`sync.sh` detecta qué apps existen (`~/.copilot`, `~/.claude`, `~/.agents`, OpenCode) y copia a cada una las fuentes que declara `config/apps.json`. Las apps no detectadas se omiten (usa `--include-missing` para forzar).

## CLI de instalación

La CLI oficial del repo es `skills-hub`.

```bash
pnpm skills-hub install [--app=<id>] [--dry-run] [--include-missing] [--verbose]
pnpm skills-hub sync    # alias de install
pnpm skills-hub status  # detección de apps + auditoría del catálogo
pnpm skills-hub doctor
pnpm skills-hub doctor-skills
pnpm skills-hub doctor-agents
pnpm skills-hub plan --profile minimal
pnpm skills-hub lint
pnpm skills-hub check
```

Flags de `install`/`sync`:

- `--app=<id>` limita a una app concreta
- `--dry-run` muestra el plan sin tocar disco
- `--include-missing` instala aunque la app no se detecte
- `--verbose` detalla cada operación de rsync

Notas:

- respeta `config/apps.json` como fuente de exposición por plataforma
- usa `pnpm skills-hub ...` dentro del repo; `pnpm exec` no expone el binario del paquete raíz

## Flujo profesional recomendado

Lee `CONTRIBUTING.md` y valida cambios locales antes de abrir PR:

```bash
./scripts/doctor-skills.sh
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

## Calidad automatizada

- CI ejecuta `./scripts/lint.sh` en cada push y pull request.
- El objetivo de CI es validar scripts y convenciones del repo sin depender de destinos locales.
- `./scripts/validate-skills.sh` valida reglas semánticas básicas: límite de 300 líneas por `SKILL.md`, naming no obsoleto y referencias legacy controladas.
- `./scripts/doctor-skills.sh` audita el catálogo canónico de skills: alineación carpeta/frontmatter, fuentes expuestas por app y colisiones de nombre por plataforma.
- `./scripts/doctor-agents.sh` audita el catálogo canónico de agents: frontmatter, referencias a skills existentes y exposición por app.
- `node ./scripts/validate-manifests.mjs` valida módulos, componentes y perfiles instalables.

## Fuente canónica y modelo de exposición

Este repo es la **fuente canónica** de authoring:

- `skills/` contiene las skills reales
- `agents/` contiene agents ligeros que enrutan hacia skills
- `config/apps.json` define qué carpetas fuente expone cada app
- `config/sync-map.sh` mantiene solo contenido legacy copiable

Las rutas locales de apps (`~/.copilot/skills`, `~/.claude/skills`, `~/.agents/skills`, OpenCode) son **targets de exposición** (copias), no sitios de mantenimiento manual. Editar la copia instalada se considera drift y `check.sh` lo detecta.

Reglas:

- un nombre de skill canónico por directorio
- un nombre de agent canónico por fichero
- carpeta/fichero y frontmatter `name` deben coincidir
- no duplicar el mismo nombre de skill o agent dentro del conjunto expuesto a una misma app
- tras renames, actualizar también prompts, config gestionada y referencias

## Criterio de clasificación

- Por defecto una skill va a `skills/common`: la consumen Claude, Copilot y agents.
- Solo va a `skills/copilot-only` o `skills/claude-only` si **depende** de esa plataforma concreta.
- No mezclar configuración de máquina dentro de `skills/`; eso queda en el tooling o fuera del repo.

## Convención global de package manager

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


### Agents vs skills

- Un **agent** es un rol/persona breve: decide, revisa, coordina y enruta.
- Una **skill** es el protocolo profundo de una tarea reutilizable.
- Los agents deben referenciar skills existentes en frontmatter `skills:` y no duplicar el contenido largo de `SKILL.md`.
- La instalación de agents es selectiva por perfil para evitar context bloat.

## Contenido legacy copiable

`prompts/` se trata como contenido copiable y se sincroniza con `rsync` (par definido en `config/sync-map.sh`). `sync.sh` ejecuta ese paso después de copiar las skills.

## GitFlow del repositorio

- `main` para releases
- `develop` para integración
- `feature/*` desde `develop`
- `release/vX.Y.Z` desde `develop`
- `hotfix/*` desde `main`

Referencia completa: `GITFLOW.md`, `BRANCH_PROTECTION.md`, `RELEASING.md`.

## Historial de cambios

- Ver `CHANGELOG.md` para cambios notables del proyecto.
- Ver `RELEASING.md` para el proceso de versionado y publicación.

## Gobernanza y seguridad

- Ver `CONTRIBUTING.md` para flujo de contribución.
- Ver `SECURITY.md` para reporte responsable de vulnerabilidades.
- Ver `.github/CODEOWNERS` para propiedad de revisión por rutas.
- Ver `BRANCH_PROTECTION.md` para enforcement de checks en `main`.
