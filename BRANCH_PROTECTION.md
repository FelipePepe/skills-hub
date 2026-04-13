# Branch Protection Guide

Este proyecto recomienda proteger `main` con checks obligatorios y review minima.

## Prerrequisitos

- Tener `gh` instalado.
- Tener sesion iniciada en GitHub CLI:

```bash
gh auth login
```

- Tener permisos de admin en el repositorio.

## Politica versionada

- Archivo de politica: `.github/branch-protection.main.json`
- Check obligatorio configurado: `Quality / lint`

## Aplicar politica

```bash
chmod +x scripts/setup-branch-protection.sh
./scripts/setup-branch-protection.sh <owner/repo> main
```

Ejemplo:

```bash
./scripts/setup-branch-protection.sh acme/skills-hub main
```

## Verificar

```bash
gh api repos/<owner/repo>/branches/main/protection --jq '.required_status_checks.contexts'
```

## Notas

- Si cambias el nombre del job o workflow de calidad, actualiza `contexts` en `.github/branch-protection.main.json`.
- Antes de enforcement estricto, reemplaza placeholder en `.github/CODEOWNERS`.
