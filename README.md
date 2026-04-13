# skills-hub

Fuente unica de verdad para skills y prompts.

## Objetivo

Mantener contenido versionado en un solo repositorio y sincronizarlo hacia:

- ~/.copilot/skills
- ~/.claude/skills
- ~/.agents/skills
- ~/.config/Code/User/prompts

## Estructura

- `skills/common`: contenido compartido entre plataformas.
- `skills/copilot-only`: contenido exclusivo para Copilot.
- `skills/claude-only`: contenido exclusivo para Claude.
- `prompts`: prompts globales e instrucciones.
- `config/sync-map.sh`: mapeos origen -> destino para sincronizacion.
- `scripts/sync.sh`: aplica sincronizacion.
- `scripts/check.sh`: valida drift y consistencia.

## Uso rapido

```bash
./scripts/doctor.sh
./scripts/lint.sh
./scripts/sync.sh --dry-run
./scripts/sync.sh
./scripts/check.sh
```

## Flujo profesional recomendado

- Lee la guia de contribucion: `CONTRIBUTING.md`
- Valida cambios locales antes de abrir PR:

```bash
./scripts/doctor.sh
./scripts/lint.sh
./scripts/check.sh
```

- Usa templates de issue y pull request en `.github/`.

## Calidad automatizada

- CI ejecuta `./scripts/lint.sh` en cada push y pull request.
- El objetivo de CI es validar scripts y convenciones del repo sin depender de destinos locales.

## Historial de cambios

- Ver `CHANGELOG.md` para cambios notables del proyecto.
- Ver `RELEASING.md` para el proceso de versionado y publicacion.

## Gobernanza y seguridad

- Ver `CONTRIBUTING.md` para flujo de contribucion.
- Ver `SECURITY.md` para reporte responsable de vulnerabilidades.
- Ver `.github/CODEOWNERS` para propiedad de revision por rutas.
- Ver `BRANCH_PROTECTION.md` para enforcement de checks en `main`.
