---
name: poc-init
description: >
  Inicializa un nuevo proyecto PoC con el stack estándar: Angular 21 +
  Express/TypeScript + Drizzle ORM + OpenAPI + GitFlow + CLAUDE.md + estructura
  lista para deploy-casa. Trigger: "crea un nuevo poc", "nuevo proyecto",
  "inicializa el proyecto X", "scaffolding para X".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.1"
---

## Cuándo usar

- El usuario quiere arrancar un proyecto nuevo desde cero.
- Pide un PoC, scaffold o proyecto estándar para la intranet `.casa`.
- Hay que crear base frontend+backend sin reinventar estructura.

## Stack estándar

| Capa | Tecnología |
|------|------------|
| Frontend | Angular 21 + Angular Material/CDK |
| Estado | Signals + RxJS |
| Backend | Express + TypeScript |
| ORM/DB | Drizzle ORM + PostgreSQL |
| API | OpenAPI 3.0 |
| Tests | Vitest |
| Calidad | ESLint + Prettier + Lefthook |
| Deploy | compatible con `deploy-casa` |

## Protocolo rápido

1. Confirmar nombre del proyecto, dominio `.casa` deseado y si necesita auth.
2. Crear repo con estructura:

```text
<proyecto>/
├── backend/
├── frontend/
├── .github/copilot-instructions.md
├── CLAUDE.md
├── lefthook.yml
└── start-dev.sh
```

3. Inicializar GitFlow:

```bash
git init
git checkout -b main
git checkout -b develop
git checkout -b feature/init
```

4. Generar `.env.example`, nunca secrets reales.
5. Añadir OpenAPI, tests mínimos y scripts de dev/build/test.
6. Validar que backend y frontend arrancan antes de darlo por terminado.

## Referencia detallada

Para árbol completo de carpetas, ejemplos de `package.json`, OpenAPI, Drizzle, Angular, scripts y checklist final, cargar:

- `references/full-protocol.md`

## Reglas

- No crear secrets reales en `.env`; usar `.env.example` o Infisical si aplica.
- Mantener TypeScript strict en backend y frontend.
- Usar controladores funcionales Express, no clases, salvo que el proyecto pida otra cosa.
- Cada PoC debe salir con tests mínimos y `start-dev.sh` funcional.
- Si el usuario quiere algo más pequeño que el stack estándar, reducir alcance explícitamente.
