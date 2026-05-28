---
name: trello-api-client
description: >
  CLI para gestionar el Trello clone de la intranet .CASA.
  Crear boards, listas, cards, moverlas, asignarlas.
  Integración con SDD, Atlas y Portal.
  Trigger: "trello board", "trello card", "trello list", "crear tablero trello",
  "move card", "add card", "trello new", "mover tarjeta"
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---

# Trello API Client - Documentación Modular

## 📋 Tabla de Contenidos

| Archivo | Descripción |
|---------|-------------|
| [`architecture.md`](architecture.md) | Arquitectura del servicio, puertos, DB |
| [`commands.md`](commands.md) | Todos los comandos CLI |
| [`api-reference.md`](api-reference.md) | Endpoints de la API REST |
| [`models.md`](models.md) | Modelos de datos y tipos |
| [`integration-sdd.md`](integration-sdd.md) | Integración con Spec-Driven Development |
| [`integration-atlas.md`](integration-atlas.md) | Sincronización con Atlas/Obsidian |
| [`integration-portal.md`](integration-portal.md) | Dashboard y métricas en Portal |
| [`troubleshooting.md`](troubleshooting.md) | Solución de problemas |
| [`examples.md`](examples.md) | Ejemplos de uso completo |

## ✅ Estado del Servicio

```bash
# Verificar que el backend está activo
sudo systemctl status poc-trello

# Puerto actual
🟢 LISTEN en 3002 (nativo, NO Docker)

# Logs en tiempo real
sudo journalctl -u poc-trello -f
```

## 🎯 Quick Start

```bash
# 1. Autenticar
trello login

# 2. Crear un board
trello board create "Mi Proyecto" --desc "Tablero para desarrollo"

# 3. Crear columnas
trello list create <board-id> "To Do"
trello list create <board-id> "In Progress"
trello list create <board-id> "Done"

# 4. Crear una tarea
trello card create <list-id> "Implementar algo" --desc "Descripción"

# 5. Mover tarea
trello card move-to <card-id> --column "In Progress"
```

## 📖 Documentación Detallada

### Arquitectura
Ver [`architecture.md`](architecture.md) para:
- Configuración del servicio systemd
- PostgreSQL nativa
- Nginx proxy
- Troubleshooting

### Comandos CLI
Ver [`commands.md`](commands.md) para:
- Autenticación
- Gestión de boards
- Gestión de listas/columnas
- Gestión de cards
- Custom fields
- Integraciones SDD/Atlas/Portal

### API Reference
Ver [`api-reference.md`](api-reference.md) para:
- Todos los endpoints
- Request/response bodies
- Códigos de error

### Integraciones
- [`integration-sdd.md`](integration-sdd.md) - Spec-Driven Development
- [`integration-atlas.md`](integration-atlas.md) - Documentación automática
- [`integration-portal.md`](integration-portal.md) - Dashboard en vivo

### Ejemplos
Ver [`examples.md`](examples.md) para:
- Flujo SDD completo
- Flujo manual simple
- Comandos de diagnóstico

## 🚨 Troubleshooting Rápido

| Problema | Comando |
|---|--|
| Servicio caído | `sudo systemctl restart poc-trello` |
| Ver logs | `sudo journalctl -u poc-trello -n 50` |
| Puerto ocupado? | `sudo ss -tlnp | grep 3002` |
| API 404 | Verificar servicio: `curl http://localhost:3002/health` |
| Nginx falló | `sudo nginx -t && sudo systemctl reload nginx` |

## 🔌 Referencias

- **Swagger UI:** http://localhost:3002/api-docs
- **Código:** `/mnt/nas/sources/pocs/poc-trello/`
- **DB:** PostgreSQL nativa (`poc_trello`, user: `trello`)
- **Service:** `/etc/systemd/system/poc-trello.service`

