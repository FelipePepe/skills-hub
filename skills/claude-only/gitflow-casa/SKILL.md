---
name: gitflow-casa
description: >
  Aplica GitFlow correctamente en cualquier repositorio: feature/* → develop →
  release → main. Revisa rama/estado, detecta violaciones, guía commits,
  merges, tags y lefthook. Trigger: commit, merge, release, hooks, "qué rama
  toca", "cómo lo subo", "sigo gitflow?".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.2"
---

## Cuándo usar

- El usuario quiere commitear, mergear, publicar o etiquetar una versión.
- Pregunta qué rama toca o si el repo cumple GitFlow.
- Hay cambios o commits en ramas incorrectas.
- Quiere configurar/verificar lefthook.

## Protocolo rápido

1. Diagnosticar antes de tocar nada:

```bash
git branch --show-current
git status --short
git log --oneline -5
git branch -a | grep -E "main|develop|feature|release|hotfix"
```

2. Aplicar modelo:

```text
main      ← releases/hotfixes, nunca commits directos
develop   ← integración
feature/* ← sale de develop y vuelve a develop
release/* ← sale de develop, mergea a main y develop
hotfix/*  ← sale de main, mergea a main y develop
```

3. Si se va a trabajar en código nuevo:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/<nombre-kebab-case>
```

4. Commit convencional:

```text
<tipo>(<scope>): <descripción imperativa en minúsculas sin punto>
```

Tipos: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `chore`, `ci`, `revert`.

5. Si hay release/hotfix o lefthook, leer el protocolo completo.

## Referencia detallada

Para comandos completos de release/hotfix, reglas de commit, `lefthook.yml`, hooks y troubleshooting, cargar:

- `references/full-protocol.md`

## Reglas

- Nunca hacer commit directo en `main` ni `develop`.
- Si falta `develop`, proponer crearlo desde `main` antes de seguir.
- Si hay cambios sin commitear, no cambiar de rama sin protegerlos primero.
- Si detectas una violación de GitFlow, explicar el riesgo y proponer el arreglo mínimo.
- No saltar hooks salvo justificación explícita del usuario.
