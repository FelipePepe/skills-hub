---
name: casa-deploy
description: >
  Despliega servicios en producción en maya via docker compose pull + up -d.
  Trigger: cuando el usuario quiere hacer deploy o actualizar un servicio en producción.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- El usuario dice "haz deploy de X" o "actualiza X en producción" o "despliega X"
- Se acaba de mergear una feature y hay que desplegar
- Un servicio necesita reiniciarse con nueva configuración

## Infraestructura

| Dato | Valor |
|------|-------|
| Máquina prod | maya (192.168.1.55) |
| Runtime | Docker Compose |
| Directorios típicos | `/home/felipe/<service>` o `/home/felipe/Sources/<service>` |

## Comando

```bash
# Auto-detect directorio del servicio
ssh -o BatchMode=yes felipe@192.168.1.55 'casa deploy <service>'

# Con directorio explícito
ssh -o BatchMode=yes felipe@192.168.1.55 'casa deploy <service> --dir /home/felipe/Sources/mi-proyecto'
```

## Lo que hace

1. Busca el directorio: primero `/home/felipe/<service>`, luego `/home/felipe/Sources/<service>`
2. Ejecuta `docker compose pull`
3. Ejecuta `docker compose up -d`
4. Hace health check básico post-deploy

## Servicios conocidos en maya

| Servicio | Directorio |
|---------|-----------|
| `infisical` | `/home/felipe/infisical` |
| `bitwarden-clone` | `/home/felipe/bitwarden-clone` |
| `searxng` | `/home/felipe/searxng` |

## Verificar deploy

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
```

## Notas

- Si el servicio usa Infisical para secrets, los secrets se cargan en runtime — no hay que hacer nada extra
- Si hay migraciones de DB, ejecutarlas antes del deploy
- Los logs post-deploy: `ssh felipe@192.168.1.55 'docker logs <container> --tail 50'`

## Model routing hints

- preferred agent: repo-agent
- preferred model: ollama/devstral:latest
- routing intent: hint only; the skill must not switch models directly
