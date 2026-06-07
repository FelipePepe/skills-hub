---
name: casa-vault
description: >
  Creates projects in Infisical (secrets vault) for new projects. Replaces manual .env creation.
  Trigger: when a new project is started and needs secrets/environment variables.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- A new project is being created and it needs environment variables / secrets
- The user says "create the vault for X" or "initialize infisical for X"
- A project needs DATABASE_URL, JWT_SECRET, API_KEY, etc.

## Infrastructure

| Service | URL | Machine |
|---------|-----|---------|
| Infisical | http://infisical.casa | maya (192.168.1.55) |
| Local API | http://localhost:8888 | maya (from maya) |

## Command

```bash
# Create vault for a project with default environments (dev, staging, prod)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa vault init <project-name>'

# With custom environments
ssh -o BatchMode=yes felipe@192.168.1.55 'casa vault init <project-name> --envs dev,prod'
```

## What It Does

1. Authenticates to the Infisical API (http://localhost:8888) as admin
2. Creates the project with the given name
3. Creates the specified environments
4. Creates a Machine Identity with Universal Auth for programmatic access
5. Prints `clientId` and `clientSecret` for use in the project

## Expected Output

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

## After Creating the Vault

The agent must:
1. Add `clientId` and `clientSecret` to the project **only as bootstrap variables** in a minimal `.env`
2. All real secrets go directly to Infisical
3. See skill `infisical-vault` for the code usage pattern

## Admin Credentials (only for this CLI)

They are embedded in the casa CLI. Do not expose them in project code.

## Model routing hints

- preferred agent: security
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
