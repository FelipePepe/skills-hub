---
name: infisical-admin-mcp
description: >
  Provisiona proyectos y credenciales bootstrap en Infisical usando el MCP global
  `infisical-admin`. Trigger: cuando el usuario pide crear un proyecto/vault en
  Infisical, sacar `clientId` y `clientSecret`, crear o reutilizar machine identities,
  inicializar Universal Auth, o automatizar tareas de administración de Infisical
  sin ir manualmente a la UI.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---

Usa el MCP global `infisical-admin` como camino preferido para operaciones de provisioning
en Infisical. No vayas primero a la UI ni a flujos manuales si el MCP cubre la tarea.

## Cuándo usar esta skill

- El usuario pide `clientId` y `clientSecret`
- El usuario quiere crear o inicializar un proyecto/vault en Infisical
- El usuario quiere crear o reutilizar una machine identity
- El usuario quiere automatizar Universal Auth o bootstrap credentials

## Tools MCP preferidas

- `infisical_list_projects`
- `infisical_bootstrap_project`
- `infisical_ensure_credentials`

## Flujo recomendado

1. Si no está claro si el proyecto existe, usa `infisical_list_projects`.
2. Si el usuario quiere crear o preparar todo desde cero, usa `infisical_bootstrap_project`.
3. Si el proyecto ya existe y solo faltan credenciales, usa `infisical_ensure_credentials`.
4. Devuelve al usuario `projectId`, `identityId`, `clientId` y `clientSecret` cuando aplique.

## Reglas

- Trata `clientSecret` como dato sensible.
- No escribas secretos reales en `.env` salvo credenciales bootstrap explícitamente permitidas por el proyecto.
- Si otra skill de Infisical aplica también, usa esta skill primero para provisioning y luego la otra para integración en código.
