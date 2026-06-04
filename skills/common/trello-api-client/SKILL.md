---
name: trello-api-client
description: >
  CLI para gestionar el Trello clone de la intranet .CASA (boards, listas, cards,
  custom fields) y su integración con SDD, Atlas y Portal.
  Trigger: "trello board", "trello card", "trello list", "crear tablero trello",
  "move card", "add card", "trello new", "mover tarjeta".
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.1"
---

## When to Use

Usar cuando se gestione el clon de Trello de la intranet `.CASA`: crear/mover boards,
listas o cards, definir custom fields, o sincronizar el ciclo SDD con un tablero.

## Scope Guard

Skill **environment-bound**: asume infraestructura local concreta y NO es portable.

- Backend nativo (systemd `poc-trello`) en **maya (192.168.1.55)**, puerto **3002**.
- Requiere el binario `trello` autenticado (`trello login`) con token en `~/.trello/`.
- Depende de PostgreSQL nativa (`poc_trello`) y nginx (`trello.casa`).

Fuera de ese entorno, esta skill no aplica.

## Servicio

```bash
sudo systemctl status poc-trello       # estado (🟢 LISTEN en :3002, nativo, NO Docker)
sudo journalctl -u poc-trello -f       # logs en tiempo real
```

## Quick Start

```bash
trello login                                              # 1. autenticar
trello board create "Mi Proyecto" --desc "Desarrollo"     # 2. crear board
trello list create <board-id> "In Progress"              # 3. crear columna
trello card create <list-id> "Implementar algo"          # 4. crear card
trello card move-to <card-id> --column "In Progress"     # 5. mover card
```

## Referencias

| Archivo | Contenido |
|---------|-----------|
| [`references/commands.md`](references/commands.md) | Todos los comandos CLI (auth, boards, lists, cards, fields, integraciones) + config |
| [`references/api-endpoints.md`](references/api-endpoints.md) | Endpoints REST, bodies y códigos de error |
| [`references/models.md`](references/models.md) | Modelos de datos (Board, Card, CustomField…) |
| [`references/architecture.md`](references/architecture.md) | Servicio systemd, nginx, PostgreSQL, env, diagnóstico |
| [`references/sdd-integration.md`](references/sdd-integration.md) | Mapeo de fases SDD ↔ columnas y reglas de sincronización |
| [`references/examples.md`](references/examples.md) | Flujos completos (SDD y manual) |

## Troubleshooting Rápido

| Problema | Comando |
|----------|---------|
| Servicio caído | `sudo systemctl restart poc-trello` |
| Ver logs | `sudo journalctl -u poc-trello -n 50` |
| Puerto ocupado | `sudo ss -tlnp \| grep 3002` |
| API 404 | `curl http://localhost:3002/health` |
| Nginx falló | `sudo nginx -t && sudo systemctl reload nginx` |

Detalle ampliado en [`references/architecture.md`](references/architecture.md#troubleshooting).

## Referencias del Sistema

- **Swagger UI:** http://localhost:3002/api-docs
- **OpenAPI:** `/mnt/nas/sources/pocs/poc-trello/backend/src/openapi/openapi.yaml`
- **Código:** `/mnt/nas/sources/pocs/poc-trello/`
- **Service:** `/etc/systemd/system/poc-trello.service`

## Model routing hints

- preferred agent: devops
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
