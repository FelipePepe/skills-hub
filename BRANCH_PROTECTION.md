# Branch Protection Guide

Este proyecto usa GitFlow con proteccion en `main` y `develop`.

## Prerrequisitos

- Tener `gh` instalado.
- Tener sesion iniciada en GitHub CLI:

```bash
gh auth login
```

- Tener permisos de admin en el repositorio.

## Politicas versionadas

- `main` → `.github/branch-protection.main.json`
- `develop` → `.github/branch-protection.develop.json`

Checks obligatorios:

- `Quality / lint`
- `PR Branch Policy / validate`

## Aplicar politica

```bash
chmod +x scripts/setup-branch-protection.sh
./scripts/setup-branch-protection.sh <owner/repo> main
./scripts/setup-branch-protection.sh <owner/repo> develop
```

Ejemplo:

```bash
./scripts/setup-branch-protection.sh acme/skills-hub main
./scripts/setup-branch-protection.sh acme/skills-hub develop
```

## Verificar

```bash
gh api repos/<owner/repo>/branches/main/protection --jq '.required_status_checks.contexts'
gh api repos/<owner/repo>/branches/develop/protection --jq '.required_status_checks.contexts'
```

## Notas

- Si cambias el nombre del job o workflow de calidad, actualiza `contexts` en las politicas versionadas.
- Antes de enforcement estricto, reemplaza placeholder en `.github/CODEOWNERS`.
- `required_linear_history` esta desactivado a propósito para soportar GitFlow con merges de release/hotfix trazables.
