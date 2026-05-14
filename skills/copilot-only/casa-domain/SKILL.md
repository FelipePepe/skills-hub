---
name: casa-domain
description: >
  Gestiona dominios .casa en la intranet: nginx en maya, DNS en pihole1+pihole2, y card en portal.
  Trigger: cuando el usuario quiere añadir, eliminar o listar un dominio .casa.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- El usuario dice "añade el dominio X.casa" o "crea una URL para X"
- El usuario quiere exponer un servicio nuevo en la intranet con un dominio .casa
- El usuario quiere eliminar un dominio .casa
- El usuario pregunta qué dominios .casa existen

## Infraestructura

| Componente | Máquina | IP |
|-----------|---------|-----|
| CLI `casa` | maya | 192.168.1.55 |
| nginx | maya | 192.168.1.55 |
| pihole1 DNS | pihole1 | 192.168.1.53 |
| pihole2 DNS | pihole2 | 192.168.1.54 |
| portal.casa | NAS vía maya | /mnt/nas/webs/portal.casa/index.html |

## Comandos

```bash
# Añadir dominio con nginx reverse proxy y card en portal
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'casa domain add <domain> <ip> --port <port> --portal --icon <emoji> --desc "<desc>" --machine <hostname>'

# Añadir solo DNS (sin nginx ni portal)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain add <domain> <ip>'

# Eliminar dominio
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain remove <domain>'

# Listar todos los dominios .casa
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain list'
```

## Opciones de `domain add`

| Flag | Descripción | Ejemplo |
|------|-------------|---------|
| `--port <n>` | Puerto del servicio en maya → crea nginx reverse proxy | `--port 3000` |
| `--portal` | Añade card al portal.casa | |
| `--icon <emoji>` | Icono de la card (default: 🌐) | `--icon 📊` |
| `--desc <text>` | Descripción en la card del portal | `--desc "Mi servicio"` |
| `--machine <name>` | Badge en la card (default: maya/pihole2) | `--machine maya` |

## Ejemplos reales

```bash
# Añadir Grafana en maya puerto 3000 con portal
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'casa domain add grafana.casa 192.168.1.55 --port 3000 --portal --icon 📊 --desc "Métricas y dashboards" --machine maya'

# Añadir solo DNS (servicio en otra máquina con su propio nginx)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain add nuevo.casa 192.168.1.54'

# Eliminar
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain remove grafana.casa'
```

## Lo que hace internamente

1. Crea `/etc/nginx/sites-available/<domain>` en maya + symlink a sites-enabled + reload nginx
2. Añade `address=/<domain>/<ip>` en `/etc/dnsmasq.d/local.conf` en pihole1 Y pihole2 via SSH
3. Reinicia pihole-FTL en ambos piholes
4. Si `--portal`: inserta card en Servicios + actualiza badge count en portal.casa HTML

## Verificar resultado

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain list'
# Debe aparecer el nuevo dominio
```

## Model routing hints

- preferred agent: repo-agent
- preferred model: ollama/devstral:latest
- routing intent: hint only; the skill must not switch models directly
