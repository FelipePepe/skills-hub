# Contributing Guide

Gracias por contribuir a skills-hub.

## Objetivo

Mantener este repositorio como fuente unica de verdad para sincronizar skills y prompts a destinos locales.

## Reglas clave

- Cambios pequenos y explicitos.
- No hardcodear rutas fuera de `config/sync-map.sh`.
- Mantener scripts Bash con `set -euo pipefail`.
- Evitar cambios destructivos no intencionales con `rsync --delete`.

## Flujo de trabajo

1. Crea una rama desde `main`.
2. Realiza cambios acotados.
3. Ejecuta validaciones locales:

```bash
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

4. Actualiza documentacion si cambias convenciones o estructura.
5. Abre un Pull Request usando la plantilla.

## Convenciones de cambios

- `skills/common`: contenido compartido.
- `skills/copilot-only`: contenido exclusivo de Copilot.
- `skills/claude-only`: contenido exclusivo de Claude.
- `prompts/`: prompts e instrucciones para VS Code.

## Checklist rapido antes de PR

- [ ] `./scripts/lint.sh` pasa sin errores.
- [ ] `./scripts/doctor.sh` pasa sin errores criticos.
- [ ] `./scripts/check.sh` pasa en entorno local.
- [ ] No se introdujeron rutas hardcodeadas en scripts.
- [ ] README y/o instrucciones actualizadas si aplica.

## Seguridad y ownership

- Para hallazgos sensibles, usar el proceso de `SECURITY.md` en lugar de issue publico.
- Configurar `.github/CODEOWNERS` con los handles reales antes de exigir revisiones obligatorias.
