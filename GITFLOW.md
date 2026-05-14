# GitFlow Guide

Este repositorio usa un GitFlow pragmático con dos ramas largas:

- `main` → producción / releases publicadas
- `develop` → integración de trabajo aprobado para la próxima release

## Reglas base

- Nunca hacer commits directos en `main`
- Nunca hacer commits directos en `develop`
- Todo cambio entra por Pull Request
- `main` y `develop` deben quedar protegidas
- Los commits siguen Conventional Commits

## Tipos de rama

### `feature/<slug>`

Para todo trabajo planificado que nace desde `develop`:

- nuevas features
- refactors
- docs con impacto de workflow
- tooling interno

Base:

```bash
git checkout develop
git pull
git checkout -b feature/<slug>
```

PR:

- `feature/*` → `develop`

### `release/vX.Y.Z`

Para preparar una release desde el estado integrado de `develop`.

Base:

```bash
git checkout develop
git pull
git checkout -b release/vX.Y.Z
```

Uso:

- estabilización
- docs de release
- changelog
- últimos ajustes no disruptivos

PR:

- `release/*` → `main`

Después del merge a `main`:

1. crear tag `vX.Y.Z`
2. sincronizar cambios de release de vuelta a `develop`

### `hotfix/<slug>`

Para incidencias urgentes en producción.

Base:

```bash
git checkout main
git pull
git checkout -b hotfix/<slug>
```

PR:

- `hotfix/*` → `main`

Después del merge a `main`:

1. crear tag de parche si aplica
2. sincronizar el hotfix de vuelta a `develop`

## Matriz de PR permitidos

| Rama origen | Base permitida |
|---|---|
| `feature/*` | `develop` |
| `release/*` | `main` |
| `hotfix/*` | `main` |

## Flujo normal

1. crear `feature/<slug>` desde `develop`
2. desarrollar con commits convencionales
3. abrir PR a `develop`
4. integrar varias features en `develop`
5. cortar `release/vX.Y.Z`
6. abrir PR de `release/*` a `main`
7. taggear `main`
8. sincronizar release a `develop`

## Flujo hotfix

1. crear `hotfix/<slug>` desde `main`
2. arreglar y validar
3. abrir PR a `main`
4. taggear parche si aplica
5. sincronizar a `develop`

## Comandos rápidos

```bash
# feature
git checkout develop
git pull
git checkout -b feature/<slug>

# release
git checkout develop
git pull
git checkout -b release/v1.2.0

# hotfix
git checkout main
git pull
git checkout -b hotfix/fix-installer-windows
```

## Criterio profesional para este repo

- `main` solo contiene releases
- `develop` solo recibe trabajo revisado
- no usar `required_linear_history` en GitHub branch protection, porque este flujo necesita merges de release/hotfix bien trazables
- los cambios de release/hotfix deben volver a `develop` antes de cerrar el ciclo
