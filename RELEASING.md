# Releasing Guide

Este proyecto usa Semantic Versioning y Keep a Changelog.

## Checklist de release

1. Verifica estado del repo:

```bash
git status --short
```

2. Ejecuta validaciones:

```bash
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

3. Actualiza `CHANGELOG.md`:
- Mueve cambios de `Sin publicar` a una nueva version `## [x.y.z] - YYYY-MM-DD`.
- Deja `Sin publicar` como seccion vacia para cambios futuros.

4. Crea commit de release:

```bash
git add CHANGELOG.md README.md RELEASING.md
git commit -m "chore(release): prepare vX.Y.Z"
```

5. Crea tag anotado:

```bash
git tag -a vX.Y.Z -m "release: vX.Y.Z"
```

6. Publica rama y tag:

```bash
git push
git push origin vX.Y.Z
```

7. Release automatica en GitHub:
- El workflow `.github/workflows/release.yml` se dispara al pushear tags `v*`.
- Se publica un release con notas autogeneradas.

## Enlaces de comparacion en changelog

Si el repo aun no tiene remoto `origin`, deja placeholders en `CHANGELOG.md`.
Cuando exista `origin`, reemplaza `<org>/<repo>` con la URL real de GitHub.
