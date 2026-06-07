---
name: casa-vault
description: >
  Crea proyectos en Infisical (vault de secretos) para nuevos proyectos. Reemplaza la creación manual de .env.
  Trigger: cuando se inicia un nuevo proyecto y necesita secretos/variables de entorno.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- Se va a crear un nuevo proyecto y necesita variables de entorno / secretos
- El usuario dice "crea el vault para X" o "inicializa infisical para X"
- Un proyecto necesita DATABASE_URL, JWT_SECRET, API_KEY, etc.

## Infraestructura

| Servicio | URL | Máquina |
|----------|-----|---------|
| Infisical | http://infisical.casa | maya (192.168.1.55) |
| API local | http://localhost:8888 | maya (desde maya) |

## Comando

```bash
# Crear vault para un proyecto con environments por defecto (dev, staging, prod)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa vault init <project-name>'

# Con environments personalizados
ssh -o BatchMode=yes felipe@192.168.1.55 'casa vault init <project-name> --envs dev,prod'
```

## Lo que hace

1. Autentica en Infisical API (http://localhost:8888) como admin
2. Crea el proyecto con el nombre dado
3. Crea los environments especificados
4. Crea una Machine Identity con Universal Auth para acceso programático
5. Imprime `clientId` y `clientSecret` para usar en el proyecto

## Output esperado

```
✔ Project created: my-project (slug: my-project)
✔ Environments created: dev, staging, prod
✔ Machine Identity created: my-project-identity
  clientId:     abc123...
  clientSecret: xyz789...

Next steps:
  1. Go to http://infisical.casa and add your secrets to the project
  2. Add to your backend/src/secrets.ts:
     const client = new InfisicalSDK({ siteUrl: 'http://infisical.casa' })
     await client.auth().universalAuth.login({ clientId, clientSecret })
```

## Tras crear el vault

El agente debe:
1. Añadir `clientId` y `clientSecret` al proyecto **solo como variables bootstrap** en un `.env` mínimo
2. Todos los secretos reales van a Infisical directamente
3. Ver skill `infisical-vault` para el patrón de uso en código

## Credenciales admin (solo para este CLI)

Están embebidas en el CLI de casa. No exponer en código de proyecto.

## Model routing hints

- preferred agent: security
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
