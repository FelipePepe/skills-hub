# Full Protocol

---
name: gitflow-casa
description: >
  Aplica gitflow correctamente en cualquier repositorio: feature/* → develop →
  release → main. Revisa el estado git actual, detecta violaciones del flujo,
  guía cada paso (branch, commit, merge, tag) y gestiona lefthook (instalación,
  hooks pre-commit: gitleaks, prettier, eslint). Trigger: el usuario quiere
  hacer un commit, merge, release, configurar hooks, o dice "sigo gitflow?",
  "cómo lo subo", "qué rama toca", "configura lefthook".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.1"
---

## Cuándo usar este skill

- El usuario quiere commitear, mergear o publicar cambios
- El usuario pregunta en qué rama está o qué rama toca
- Se detecta que hay cambios en una rama incorrecta (ej: commits en `main` directamente)
- Al arrancar trabajo nuevo sobre un repo
- El usuario quiere configurar o verificar lefthook en un proyecto

---

## Modelo de ramas

```
main        ← solo recibe merges de release/* o hotfix/*. Nunca commits directos.
develop     ← integración. Recibe merges de feature/* y hotfix/*.
feature/*   ← trabajo nuevo. Sale de develop, vuelve a develop.
release/*   ← preparación de versión. Sale de develop, mergea a main Y develop.
hotfix/*    ← fix urgente en producción. Sale de main, mergea a main Y develop.
```

**Regla crítica**: Nunca hacer `git commit` directamente en `main` ni en `develop`.

---

## Paso 1 — Diagnóstico inicial

```bash
git branch --show-current          # rama actual
git status                         # cambios pendientes
git log --oneline -5               # últimos commits
git branch -a | grep -E "main|develop|feature|release|hotfix"
```

Evaluar:
- ¿Estamos en la rama correcta para lo que se quiere hacer?
- ¿Hay commits en `main` o `develop` que deberían estar en una `feature/*`?
- ¿Existe rama `develop`? Si no, crearla desde `main`.

---

## Paso 2 — Flujos habituales

### Trabajo nuevo (feature)

```bash
git checkout develop
git pull origin develop            # sincronizar antes de ramificar
git checkout -b feature/<nombre>   # nombre en kebab-case, descriptivo

# ... trabajo, commits ...
git add <archivos>
git commit -m "feat(<scope>): descripción"

# Cuando está listo:
git checkout develop
git merge --no-ff feature/<nombre>
git push origin develop
git branch -d feature/<nombre>
```

### Publicar versión (release)

```bash
git checkout develop
git pull origin develop
git checkout -b release/<semver>   # ej: release/1.2.0

# Ajustes de versión, CHANGELOG, últimos fixes...
git commit -m "chore: bump version to <semver>"

# Mergear a main
git checkout main
git merge --no-ff release/<semver>
git tag -a v<semver> -m "Release <semver>"
git push origin main --tags

# Mergear de vuelta a develop
git checkout develop
git merge --no-ff release/<semver>
git push origin develop

git branch -d release/<semver>
```

### Fix urgente (hotfix)

```bash
git checkout main
git pull origin main
git checkout -b hotfix/<descripcion>

# Fix + commit
git commit -m "fix(<scope>): descripción del fix"

# Mergear a main
git checkout main
git merge --no-ff hotfix/<descripcion>
git tag -a v<semver-patch> -m "Hotfix <semver-patch>"
git push origin main --tags

# Mergear a develop
git checkout develop
git merge --no-ff hotfix/<descripcion>
git push origin develop

git branch -d hotfix/<descripcion>
```

---

## Convención de mensajes de commit

### Formato completo

```
<tipo>(<scope>): <descripción>        ← subject: máx 72 caracteres

<cuerpo>                              ← opcional, separado por línea en blanco

<footer>                              ← opcional: breaking changes, issues
```

### Reglas del subject (obligatorias)

| Regla | Correcto | Incorrecto |
|-------|----------|-----------|
| Imperativo en presente | `add login page` | `added login page` / `adds login page` |
| Minúsculas | `fix cors header` | `Fix CORS header` |
| Sin punto final | `refactor auth module` | `refactor auth module.` |
| Máx 72 caracteres | — | líneas largas dificultan `git log --oneline` |
| Scope en minúsculas y kebab-case | `feat(board-detail)` | `feat(BoardDetail)` |

### Tipos

| Tipo | Cuándo usarlo |
|------|--------------|
| `feat` | Nueva funcionalidad visible para el usuario |
| `fix` | Corrección de un bug |
| `refactor` | Cambio interno sin alterar comportamiento ni añadir features |
| `perf` | Mejora de rendimiento |
| `test` | Añadir o corregir tests |
| `docs` | Solo documentación (CLAUDE.md, README, comentarios) |
| `style` | Formato, espacios, comas — sin cambio de lógica |
| `chore` | Tareas de mantenimiento: bump de versión, config, dependencias |
| `ci` | Cambios en pipelines de CI/CD |
| `revert` | Revertir un commit anterior |

### Cuerpo (cuándo escribirlo)

Escribir cuerpo cuando el subject no es suficiente para entender el **por qué**:
- La decisión no es obvia
- Se descartaron alternativas relevantes
- Hay contexto de negocio o técnico que no queda en el código

```
refactor(db): replace in-memory store with drizzle + postgresql

The in-memory store was losing all data on backend restart, making
the app unusable across sessions. Drizzle was chosen over Prisma for
its lightweight query builder and zero-codegen approach.

Closes #12
```

### Footer

```
BREAKING CHANGE: <descripción del cambio incompatible>
Closes #<issue>
Co-authored-by: Name <email>
```

### Ejemplos completos

```
feat(auth): add TOTP MFA as optional second factor
```

```
fix(api): prevent 500 on missing board id in url params

Express was passing undefined to the repository when :boardId was
omitted. Added early validation in the controller before DB call.
```

```
chore: bump version to 1.2.0
```

```
refactor(lists): extract list ordering into dedicated service

BREAKING CHANGE: GET /api/boards/:id now returns lists sorted by
position field instead of insertion order.
```

```
feat(board-detail): implement CDK drag-and-drop for card reordering

Closes #34
```

### Lo que NO es un buen mensaje de commit

```
❌  fix stuff
❌  WIP
❌  cambios varios
❌  arreglé el bug de ayer
❌  feat: implemented the new feature for the drag and drop functionality in the board detail component
```

---

## Detección de violaciones

Si se detecta alguna de estas situaciones, advertir antes de continuar:

| Situación | Riesgo | Acción |
|-----------|--------|--------|
| Commits directos en `main` | Rompe el historial de releases | Crear rama `hotfix/*` y cherry-pick |
| Commits directos en `develop` | Dificulta rollback | Crear `feature/*` retroactiva si aplica |
| `feature/*` muy desincronizada de `develop` | Conflictos al mergear | `git rebase develop` o `git merge develop` |
| Sin rama `develop` | No hay gitflow real | Crear `develop` desde el commit actual de `main` |
| Tag de versión en rama que no es `main` | Versión no trazable | Mover el tag tras mergear a `main` |

---

## Lefthook — hooks de pre-commit

### Diagnóstico

```bash
# ¿Está lefthook instalado en el repo?
ls .git/hooks/pre-commit 2>/dev/null && echo "hooks instalados" || echo "sin hooks"
cat lefthook.yml 2>/dev/null || echo "sin lefthook.yml"
```

### Instalación en un repo nuevo

```bash
# 1. Añadir como devDependency (o usar npx)
npm install --save-dev lefthook   # o: npm install -g lefthook

# 2. Crear lefthook.yml en la raíz del repo
# 3. Instalar los hooks en .git/hooks/
npx lefthook install
```

### `lefthook.yml` estándar para proyectos casa

```yaml
pre-commit:
  parallel: true
  commands:
    gitleaks:
      run: gitleaks protect --staged --redact

    prettier:
      glob: "*.{ts,html,scss,json,md}"
      run: npx prettier --write {staged_files}
      stage_fixed: true

    lint-backend:
      root: backend/
      glob: "src/**/*.ts"
      run: npm run lint -- --max-warnings 0

    lint-frontend:
      root: frontend/
      glob: "src/**/*.ts"
      run: node_modules/.bin/ng lint --quiet
```

**Ajustar según el proyecto:**
- Solo frontend (sin backend): eliminar `lint-backend`
- Solo backend (sin Angular): cambiar `lint-frontend` por `npm run lint`
- Sin prettier global: mover prettier a cada `root` con su propio config

### Hooks disponibles

| Hook | Cuándo se ejecuta | Uso habitual |
|------|------------------|-------------|
| `pre-commit` | Antes de cada commit | lint, format, secrets scan |
| `commit-msg` | Al escribir el mensaje | Validar formato convencional commits |
| `pre-push` | Antes de push | Tests, build check |

### `commit-msg` para conventional commits (recomendado)

```yaml
commit-msg:
  commands:
    validate:
      run: |
        MSG=$(head -1 {1})
        # Tipo válido, scope opcional en kebab-case, descripción en minúsculas, máx 72 chars, sin punto final
        echo "$MSG" | grep -qP "^(feat|fix|refactor|perf|test|docs|style|chore|ci|revert)(\([a-z0-9-]+\))?: [a-z].{0,69}[^.]$" \
          || (echo "
        ❌ Commit rechazado. Formato requerido:
           tipo(scope): descripción en imperativo, minúsculas, máx 72 chars, sin punto final

           Tipos: feat | fix | refactor | perf | test | docs | style | chore | ci | revert
           Ejemplo: feat(auth): add TOTP MFA support
        " && exit 1)
```

### Comandos útiles

```bash
npx lefthook install          # instalar/reinstalar hooks
npx lefthook run pre-commit   # ejecutar hooks manualmente sin commitear
npx lefthook uninstall        # eliminar hooks de .git/hooks/

# Saltar hooks puntualmente (solo si hay una razón muy justificada):
git commit --no-verify -m "..."   # ⚠️ usar con criterio
```

### Solución de problemas frecuentes

| Problema | Causa | Solución |
|----------|-------|---------|
| Hook no ejecuta | `lefthook install` no se corrió | `npx lefthook install` |
| `ng: not found` en hook de frontend | ng no está en PATH del hook | Usar `node_modules/.bin/ng` |
| Prettier reformatea y el commit falla | `stage_fixed: true` no está | Añadir `stage_fixed: true` al comando prettier |
| gitleaks falla porque no está instalado | Binario ausente | `brew install gitleaks` o `apt install gitleaks` |

---

## Repos conocidos con gitflow

| Repo | Ruta | Ramas principales |
|------|------|------------------|
| poc-trello | `/mnt/nas/sources/poc-trello` | main, develop |
| engram | `/mnt/nas/sources/engram` | main, develop |
| openclaw | `/mnt/nas/sources/openclaw` | main, develop |
| skills-hub | `/mnt/nas/sources/skills-hub` | main, develop |
| sdd-office | `/mnt/nas/sources/sdd-office` | main, develop |
