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
=======
## Arquitectura de Trello en la Intranet

| Dato | Valor |
|------|-------|
| Dominio | trello.casa |
| Máquina | maya (192.168.1.55) |
| Backend | Node + Express + PostgreSQL |
| Puerto | 3002 (evita conflicto con devmind-backend:3001) |
| API Docs | http://localhost:3002/api-docs |
| DB | PostgreSQL (poc_trello) |
| Auth | JWT + MFA opcional (TOTP) |

## Comandos CLI

### Autenticación

```bash
# Login interactivo (guarda token en ~/.trello/token)
trello login

# Logout (elimina token)
trello logout

# Ver info actual
trello whoami

# Login con credenciales directas
trello login --email admin@trello.casa --password xxxx --mfa-code 123456
```

### Boards

```bash
# Listar todos los boards
trello board list

# Crear nuevo board
trello board create "SDD Feature-X" --desc "Tablero para la feature X" --color "#0052CC"

# Obtener board por ID
trello board get <board-id>

# Actualizar board
trello board update <board-id> --title "Nuevo título" --desc "Nueva descripción"

# Archive board (soft delete)
trello board archive <board-id>

# Eliminar board (hard delete con cascada)
trello board delete <board-id>
```

### Lists (Columnas)

```bash
# Crear lista en un board
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

=======
# Listar listas de un board
trello list list <board-id>

# Reordenar listas
trello list reorder <board-id> --ids "list-1,list-2,list-3"

# Actualizar lista
trello list update <list-id> --title "Nueva columna"

# Eliminar lista (cascada: elimina cards)
trello list delete <list-id>
```

### Cards

```bash
# Crear card en lista
trello card create <list-id> "Implementar login" --desc "Descripción de la tarea"

# Atributos opcionales
trello card create <list-id> "Task title" \
  --desc "Descripción" \
  --labels "Backend,API" \
  --due-date "2026-06-01"

# Mover card a otra lista
trello card move <card-id> --list <new-list-id> --position 0

# Actualizar card
trello card update <card-id> \
  --title "Nuevo título" \
  --desc "Nueva descripción" \
  --due-date "2026-07-01"

# Obtener card por ID
trello card get <card-id>

# Listar cards de una lista
trello card list <list-id>

# Eliminar card
trello card delete <card-id>

# Mover card entre listas (workflow)
trello card move-to <card-id> --column "In Progress"
```

### Custom Fields

```bash
# Crear campo personalizado en board
trello field create <board-id> "Estado" --type select \
  --options "Pendiente,En Progreso,Hecho" \
  --show-on-card

# Crear campo texto, número, checkbox, fecha
trello field create <board-id> "Prioridad" --type text
trello field create <board-id> "Horas" --type number
trello field create <board-id> "Aprobado" --type checkbox
trello field create <board-id> "Fecha" --type date

# Establecer valor en card
trello field set <card-id> <field-id> "En Progreso"

# Obtener campos de un board
trello field list <board-id>
```

### Integración SDD

```bash
# Inicializar SDD en Trello
trello sdd-init <feature-name> \
  --columns "Propuesta,Design,Apply,Review,Done"

# Crear tasks en Trello desde SDD
trello sdd-tasks <sdd-tasks-file.json>

# Sincronizar estado SDD-Trello
trello sdd-sync --feature <feature-name>
```

### Integración Atlas

```bash
# Documentar board en Atlas
trello atlas-document <board-id>

# Sincronizar Atlas con Trello
trello atlas-sync --board <board-id>
```

### Integración Portal

```bash
# Actualizar badge en portal
trello portal-update-badge <board-id> --status "active" --count 12

# Generar snapshot para dashboard
trello portal-snapshot \
  --boards 5 \
  --output /mnt/nas/webs/portal.casa/data/snapshot.json
```

---

## API Endpoints (Internos)

### Autenticación

```http
POST /api/auth/login
Body: { email: string, password: string, mfa?: string }
Response: { accessToken: string, refreshToken: string, user: User }

POST /api/auth/refresh
Body: { refreshToken: string }
Response: { accessToken: string, refreshToken: string }

POST /api/auth/logout
Headers: Authorization: Bearer <token>
Response: 204

GET /api/auth/me
Headers: Authorization: Bearer <token>
Response: { user: { id, email, name, mfaEnabled } }

GET /api/auth/mfa/setup
Headers: Authorization: Bearer <token>
Response: { qrCodeDataUrl: string, secret: string }

POST /api/auth/mfa/verify
Body: { tempToken: string, code: string }
Response: { accessToken: string, refreshToken: string }
```

### Boards

```http
GET /api/boards
Response: Board[]

POST /api/boards
Body: { title: string, description?: string, background?: string }
Response: Board (201)

GET /api/boards/:id
Response: Board

PUT /api/boards/:id
Body: { title?: string, description?: string, background?: string }
Response: Board

DELETE /api/boards/:id
Response: 204
```

### Lists

```http
GET /api/boards/:boardId/lists
Response: BoardList[]

POST /api/boards/:boardId/lists
Body: { title: string }
Response: BoardList (201)

PATCH /api/boards/:boardId/lists/reorder
Body: { orderedIds: string[] }
Response: BoardList[]

PUT /api/lists/:id
Body: { title?: string, position?: number }
Response: BoardList

DELETE /api/lists/:id
Response: 204
```

### Cards

```http
GET /api/lists/:listId/cards
Response: Card[]

POST /api/lists/:listId/cards
Body: { title: string, description?: string, dueDate?: string, labels?: Label[] }
Response: Card (201)

PATCH /api/lists/:listId/cards/reorder
Body: { orderedIds: string[] }
Response: Card[]

PATCH /api/cards/:id/move
Body: { listId: string, position: number }
Response: Card

PUT /api/cards/:id
Body: { title?: string, description?: string, dueDate?: string, labels?: Label[] }
Response: Card

GET /api/cards/:id
Response: Card

DELETE /api/cards/:id
Response: 204
```

### Custom Fields

```http
GET /api/boards/:boardId/custom-fields
Response: CustomField[]

POST /api/boards/:boardId/custom-fields
Body: { name: string, type: 'text|number|checkbox|date|select', options?: string[] }
Response: CustomField (201)

PUT /api/custom-fields/:id
Body: { name?: string, options?: string[], position?: number, showOnCard?: boolean }
Response: CustomField

DELETE /api/custom-fields/:id
Response: 204
```

### Card Field Values

```http
GET /api/cards/:cardId/field-values
Response: CardFieldValue[]

POST /api/cards/:cardId/field-values
Body: { fieldId: string, value: string }
Response: CardFieldValue

PUT /api/cards/:cardId/field-values/:fieldId
Body: { value: string }
Response: CardFieldValue

DELETE /api/cards/:cardId/field-values/:fieldId
Response: 204
```

---

## Modelos de Datos

### Board
```typescript
{
  id: string;
  ownerId: string;
  title: string;
  description: string;
  background: string;      // hex color
  createdAt: string;
  updatedAt: string;
}
```

### BoardList
```typescript
{
  id: string;
  boardId: string;
  title: string;
  position: number;
  createdAt: string;
  updatedAt: string;
}
```

### Card
```typescript
{
  id: string;
  listId: string;
  boardId: string;
  title: string;
  description: string;
  position: number;
  labels: Label[];
  dueDate: string | null;
  createdAt: string;
  updatedAt: string;
}
```

### Label
```typescript
{
  id: string;
  name: string;
  color: string;
}
```

### CustomField
```typescript
{
  id: string;
  boardId: string;
  name: string;
  type: 'text' | 'number' | 'checkbox' | 'date' | 'select';
  options: string[] | null;
  position: number;
  showOnCard: boolean;
  createdAt: string;
  updatedAt: string;
}
```

---

## Reglas de Integración

### SDD Integration

| Fase SDD | Acción en Trello |
|-----------|-----------------|
| sdd-init | Crea board con columnas: Propuesta, Design, Apply, Review, Done |
| sdd-propose | Crea card "Propuesta" en columna Propuesta |
| sdd-design | Mueve card a columna Design |
| sdd-apply | Mueve card a columna Apply + crea cards para tasks |
| sdd-verify | Mueve cards a columna Review |
| sdd-archive | Archiva board + documenta en Atlas |

### Estado de Cards

| Columna | Estado | Significado |
|-------------|-:--:|-------------|
| Propuesta | pending | Feature en propuesta |
| Design | design | En diseño técnico |
| Apply | in-progress | Desarrollo en curso |
| Review | review | Code review/testing |
| Done | done | Completado y desplegado |

### Sincronización Bidireccional

1. SDD actualiza SQL → Actualizar card en Trello
2. Trello mueve card → Actualizar estado en SQL
3. Si hay conflicto → Resaltar al usuario para resolver manualmente

---

## Configuración

### Config File (~/.trello/config.json)
```json
{
  "baseUrl": "http://localhost:3002",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-1234",
    "email": "user@trello.casa",
    "name": "Full Name"
  }
}
```

### Environment Variables (Service)
```env
DATABASE_URL=postgresql://trello:trello2026@localhost:5432/poc_trello
PORT=3002
CORS_ORIGIN=http://trello.casa
JWT_SECRET=<random-secret-from-.env>
JWT_EXPIRY=24h
ADMIN_EMAIL=admin@trello.casa
ADMIN_PASSWORD=<secure-password>
MFA_SECRET=<optional-mfa-secret>
```

---

## Ejemplos de Uso

### Flujo SDD Completo
```bash
# 1. Inicializar feature
sdd new "auto-deploy-pipeline"

# 2. Sincronizar con Trello
trello sdd-init "auto-deploy-pipeline" \
  --columns "Propuesta,Design,Apply,Review,Done"

# 3. Crear tasks del SDD
trello sdd-tasks sdd-tasks.json

# 4. Desarrollar → mover cards
trello card move-to <card-id> --column "In Progress"

# 5. Verificar → mover a review
trello card move-to <card-id> --column "Review"

# 6. Archive → documentar
sdd archive "auto-deploy-pipeline"
trello board archive <board-id>
trello atlas-document <board-id>
```

### Flujo Manual Simple
```bash
# Crear board
trello board create "Migración a NextJS" --desc "Actualizar frontend"

# Crear columnas
trello list create <board-id> "Backlog"
trello list create <board-id> "In Progress"
trello list create <board-id> "Done"

# Crear cards
trello card create <list-id> "Instalar NextJS" --desc "v14 con App Router"
trello card create <list-id> "Migrar componentes" --desc "Pages → App Router"

# Mover tasks
trello card move-to <card-id> --column "In Progress"
trello card move-to <card-id> --column "Done"
```

---

## Error Handling

| Error | Causa | Solución |
|---|--|---:--|
| 401 Unauthorized | Token expirado o inválido | trello login |
| 403 Forbidden | No se tiene permiso al board | Verificar ownership o contactar admin |
| 404 Not Found | ID inexistente | Verificar ID del board/list/card |
| 400 Bad Request | Datos inválidos | Revisar formato de campos requeridos |
| 500 Internal | Error del servidor | Ver logs del servicio: sudo journalctl -u poc-trello |

---

## Referencias

- OpenAPI Spec: `/mnt/nas/sources/pocs/poc-trello/backend/src/openapi/openapi.yaml`
- Swagger UI: http://localhost:3002/api-docs
- Base de datos: PostgreSQL `poc_trello` en localhost
- Servicio: `/mnt/nas/sources/pocs/poc-trello/`

## Model routing hints

- preferred agent: devops
- preferred model: ollama/qwen3.6:27b
        - routing intent: hint only; the skill must not switch models directly
