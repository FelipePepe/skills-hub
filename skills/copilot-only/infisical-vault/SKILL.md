---
name: infisical-vault
description: >
  Reglas de gestión de secrets para todos los proyectos de la intranet .casa.
  A partir de ahora NO se usan ficheros .env con secrets reales. Todos los secrets
  se gestionan en Infisical self-hosted en maya.casa:8888.
  Trigger: siempre que se trabaje con secrets, variables de entorno, configuración
  de conexiones (DB, JWT, API keys) o se mencione .env en cualquier proyecto.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.1"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## Regla principal (CRÍTICA)

> **NUNCA crear ni editar `.env` con secrets reales.** Usar siempre Infisical.

Si el usuario o el contexto pide crear un `.env`, un `.env.local`, o poner un secret
en texto plano en cualquier fichero: **detente, explica la política y usa Infisical**.

Las únicas excepciones permitidas en `.env` son las credenciales bootstrap de Infisical:
`INFISICAL_CLIENT_ID`, `INFISICAL_CLIENT_SECRET`, `INFISICAL_SITE_URL` y `USE_DATABASE`.
Todo lo demás (DATABASE_URL, JWT_SECRET, API keys…) va en el vault.

---

## Infraestructura del Vault

| Dato | Valor |
|------|-------|
| **URL** | `http://maya.casa:8888` |
| **Máquina** | `maya.casa` — `192.168.1.55` |
| **Docker Compose** | `/mnt/nas/sources/infisical/docker-compose.yml` en `felipe@192.168.1.55` |
| **Admin** | `admin@bitwarden.casa` / ver Infisical |
| **Admin SSH** | `felipe@192.168.1.55` (sin password, clave SSH) |

---

## Cómo integrarse (Node / TypeScript)

### 1. Instalar el SDK

```bash
pnpm add @infisical/sdk
```

### 2. Módulo de secrets (`src/secrets.ts`)

```typescript
import { InfisicalSDK } from '@infisical/sdk';
// ⚠️ v5 renombró InfisicalClient → InfisicalSDK. NO usar InfisicalClient.

export async function loadSecrets(): Promise<void> {
  const client = new InfisicalSDK({
    siteUrl: process.env.INFISICAL_SITE_URL ?? 'http://maya.casa:8888',
  });
  // Constructor NO acepta auth — llamar .auth() por separado
  await client.auth().universalAuth.login({
    clientId: process.env.INFISICAL_CLIENT_ID!,
    clientSecret: process.env.INFISICAL_CLIENT_SECRET!,
  });

  const projectId = 'TU_PROJECT_ID';
  const environment = 'dev';

  const secretNames = ['DATABASE_URL', 'JWT_SECRET', 'JWT_EXPIRY', 'PORT', 'CORS_ORIGIN'];
  for (const secretName of secretNames) {
    const { secretValue } = await client.secrets().getSecret({
      secretName, projectId, environment,
    });
    process.env[secretName] = secretValue;
  }
}
```

### 3. Arrancar el servidor solo tras cargar secrets

```typescript
// server.ts — los imports dinámicos garantizan que env.ts (Zod) parsea
// DESPUÉS de que loadSecrets() haya inyectado los valores en process.env
import 'dotenv/config';           // solo carga bootstrap (.env)
import { loadSecrets } from './secrets';

await loadSecrets();
const [{ default: app }, { env }] = await Promise.all([
  import('./app'),                // dynamic: AFTER secrets
  import('./env'),                // Zod .parse(process.env) aquí
]);
app.listen(env.PORT);
```

### 4. Variables de entorno mínimas necesarias (sí van en el entorno del proceso)

```dotenv
# .env — solo bootstrap (esto SÍ va en .env, no contiene secretos reales)
INFISICAL_SITE_URL=http://maya.casa:8888
INFISICAL_CLIENT_ID=<machine-identity-client-id>
INFISICAL_CLIENT_SECRET=<machine-identity-client-secret>
USE_DATABASE=true
NODE_ENV=development
```

> **Cómo obtener clientId:** En Infisical UI → Identity → Universal Auth →
> `identityUniversalAuth.clientId` — NO es el `identityId`, son distintos.

---

## Secrets que gestiona Infisical para bitwarden-clone

| Key | Descripción |
|-----|-------------|
| `DATABASE_URL` | PostgreSQL en maya.casa |
| `JWT_SECRET` | Clave de firma JWT |
| `JWT_EXPIRY` | Expiración del token (`24h`) |
| `MFA_ISSUER` | Issuer TOTP (`bitwarden.casa`) |
| `PORT` | Puerto del servidor Express |
| `CORS_ORIGIN` | Origen permitido (`http://localhost:4200`) |

---

## Flujo para añadir un nuevo secret

1. Abre `http://maya.casa:8888` → proyecto → entorno
2. Añade el secret con su key/value
3. Actualiza el tipo `Secrets` en `src/secrets.ts` si es TypeScript
4. **Nunca** lo pongas en `.env`, `app.yaml`, `docker-compose.yml` ni en código

---

## .env.example sigue existiendo

El fichero `.env.example` **sí se mantiene** en el repo como documentación de qué
keys existen, pero con valores de ejemplo (`change-me`, `your-value-here`).
Nunca contiene valores reales.

## Model routing hints

- preferred agent: security
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
