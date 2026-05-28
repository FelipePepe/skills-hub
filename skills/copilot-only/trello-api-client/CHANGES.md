# ARCHITECTURE UPDATE - Trello Clone API

## ✅ SERVICE RESTORED

**Status:** WORKING since May 27, 2026 - Puerto 3002

## Architecture Correction

### BEFORE (Incorrect)
```
❌ Docker: Trello corría como contenedor
❌ Puerto: 3001
❌ Servidor: Docker compose
```

### AFTER (Correct)
```
✅ Docker: NO usa Docker - ES NATIVO (systemd)
✅ Puerto: 3002 (evita conflicto con devmind-backend:3001)
✅ Servidor: systemctl poc-trello
✅ Location: /mnt/nas/sources/pocs/poc-trello/backend/
✅ User: felipe
```

## Service Details

```bash
# Service name
sudo systemctl status poc-trello

# Process
PID: node dist/src/server.js (felipe)
Port: 3002
DB: PostgreSQL nativa (localhost:5432, DB: poc_trello)

# Nginx config (en maya)
/etc/nginx/sites-available/trello.casa
  - Proxy API → http://127.0.0.1:3002
  - Static → /mnt/nas/webs/trello.casa/

# Environment file
/mnt/nas/sources/pocs/poc-trello/backend/.env
```

## Database

```bash
# PostgreSQL nativa (NO docker)
sudo -u postgres psql -d poc_trello -c '\dt'

# Tablas:
# - users
# - auth_sessions
# - boards
# - lists
# - cards
# - custom_fields
# - card_custom_field_values
```

## Troubleshooting

| Problema | Solución |
|---|--:--|
| Servicio caído | `sudo systemctl restart poc-trello` |
| Puerto ocupado | `sudo ss -tlnp | grep 3002` |
| Ver logs | `sudo journalctl -u poc-trello -n 50 --no-pager` |
| DB no responde | `sudo systemctl status postgresql` |
| API 404 | Verificar que servicio está activo |
| nginx falla | `sudo nginx -t && sudo systemctl reload nginx` |

## Files Modified

1. `/mnt/nas/sources/pocs/poc-trello/backend/.env` - Puerto 3001 → 3002
2. `/etc/nginx/sites-available/trello.casa` - Proxy 3001 → 3002
3. `/mnt/nas/sources/poc-trello` - Symlink a `/mnt/nas/sources/pocs/poc-trello`

## Swagger/Docs

- **URL:** http://localhost:3002/api-docs
- **Spec:** `/mnt/nas/sources/pocs/poc-trello/backend/src/openapi/openapi.yaml` (18KB)

✅ **Swagger ya existe!** No necesita crear nuevos documents.

## Next Steps

1. Crear skill `trello-api-client` completa
2. Implementar CLI commands
3. Integrar con SDD
4. Integrar con Atlas
5. Integrar con Portal
