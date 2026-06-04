---
name: deploy-casa
description: >
  Despliega una aplicación web en la intranet .casa: compila el frontend, copia
  los artefactos a /mnt/nas/webs/<dominio>/, configura nginx en maya, añade DNS
  en ambos Pi-holes y registra la app en portal.casa.
  Trigger: El usuario pide "despliega", "instala en nginx", "añade a portal.casa",
  "publica en la intranet" o similares.
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## Cuándo usar este skill

- El usuario pide desplegar una app web en la red local `.casa`
- El usuario dice "instala en nginx", "añade a portal.casa", "publica en la intranet"
- Se acaba de desarrollar un frontend nuevo y se quiere servir en la red

---

## Infraestructura de referencia

| Máquina | IP | Rol |
|---------|----|-----|
| maya | 192.168.1.55 | Servidor nginx, NAS montado en `/mnt/nas` |
| pihole1 | 192.168.1.53 | DNS primario |
| pihole2 | 192.168.1.54 | DNS secundario, portal.casa |

**Rutas clave en maya:**

| Ruta | Propósito |
|------|-----------|
| `/mnt/nas/webs/<dominio>/` | Raíz de producción de frontends estáticos |
| `/mnt/nas/sources/<proyecto>/` | Código fuente |
| `/etc/nginx/sites-available/` | Configs nginx |
| `/etc/dnsmasq.d/local.conf` | DNS en cada Pi-hole (vía SSH) |
| `/etc/hosts` | Workaround DNS local de maya |
| `/mnt/nas/webs/portal.casa/index.html` | Dashboard portal.casa |

**Puertos ocupados en maya:**

| Puerto | Servicio |
|--------|---------|
| 3000 | obsidian-api |
| 3001 | poc-trello backend |
| 9100 | node_exporter |
| 5432 | postgresql |

---

## Protocolo de despliegue

### Paso 1 — Recopilar información

Antes de empezar, determinar:
- **Dominio**: `<nombre>.casa` (seguir patrón existente: `trello.casa`, `oficina.casa`…)
- **Tipo**: solo frontend estático / frontend + backend Node.js
- **Framework frontend**: Angular (`ng build`), React/Vite (`npm run build`), otro
- **Puerto del backend** (si aplica): elegir uno libre en maya

### Paso 2 — Compilar frontend

```bash
cd /mnt/nas/sources/<proyecto>/frontend   # o raíz si es SPA directa

# Instalar dependencias si node_modules no existe
npm install

# Angular
node_modules/.bin/ng build --configuration production

# Vite / React
npm run build
```

**Directorio de salida habitual:**
- Angular: `dist/<nombre>/browser/`
- Vite: `dist/`

### Paso 3 — Copiar a producción en NAS

```bash
mkdir -p /mnt/nas/webs/<dominio>.casa
cp -r <ruta-dist>/. /mnt/nas/webs/<dominio>.casa/
```

### Paso 4 — Configurar nginx en maya

Crear `/etc/nginx/sites-available/<dominio>.casa`:

```nginx
server {
    listen 80;
    server_name <dominio>.casa;

    root /mnt/nas/webs/<dominio>.casa;
    index index.html;

    # Solo si hay backend Node.js:
    location /api/ {
        proxy_pass http://127.0.0.1:<puerto-backend>;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
sudo ln -sf /etc/nginx/sites-available/<dominio>.casa /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Paso 5 — Añadir DNS en ambos Pi-holes

```bash
# En pihole1 (192.168.1.53) y pihole2 (192.168.1.54):
for host in 192.168.1.53 192.168.1.54; do
  ssh $host "echo 'address=/<dominio>.casa/192.168.1.55' | sudo tee -a /etc/dnsmasq.d/local.conf && sudo systemctl restart pihole-FTL && echo ok"
done
```

> ⚠️ **NO usar `/etc/pihole/custom.list`** — no funciona en esta instalación.
> El DNS real está en `/etc/dnsmasq.d/local.conf` en cada Pi-hole.

### Paso 6 — Añadir entrada en /etc/hosts de maya

```bash
echo "192.168.1.55 <dominio>.casa" | sudo tee -a /etc/hosts
```

> ⚠️ **Obligatorio**: maya tiene `mdns4_minimal [NOTFOUND=return]` en `/etc/nsswitch.conf`
> que impide resolver dominios `.casa` vía DNS. Sin esta entrada, maya misma no resuelve el dominio.

### Paso 7 — Backend Node.js (si aplica)

Crear servicio systemd en `/etc/systemd/system/<proyecto>.service`:

```ini
[Unit]
Description=<proyecto> backend
After=network.target postgresql.service

[Service]
Type=simple
User=felipe
WorkingDirectory=/mnt/nas/sources/<proyecto>/backend
EnvironmentFile=/mnt/nas/sources/<proyecto>/backend/.env
ExecStart=/home/felipe/.nvm/versions/node/v22.22.0/bin/node dist/src/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

> ⚠️ El entry point compilado es `dist/src/server.js`, **no** `dist/server.js`
> (tsc respeta la estructura de `src/`).

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now <proyecto>
sudo systemctl status <proyecto>
```

**Tras cada build hay que copiar assets estáticos manualmente** (tsc no los incluye):
```bash
# Ejemplo: openapi.yaml
cp -r src/openapi dist/src/openapi
```

### Paso 8 — Añadir card en portal.casa

Editar `/mnt/nas/webs/portal.casa/index.html`:

1. Incrementar `<span class="section-badge">N</span>` en la sección "Servicios"
2. Añadir card antes del cierre `</div></div>` de la sección:

```html
<a class="card" href="http://<dominio>.casa" data-check="http://<dominio>.casa" data-name="<palabras clave de búsqueda>">
  <div class="card-top"><div class="card-icon">🎯</div><div class="dot checking"></div></div>
  <div class="card-name"><Nombre visible></div>
  <div class="card-desc"><Descripción breve.></div>
  <div class="card-meta"><span class="card-url"><dominio>.casa</span><span class="badge">maya</span></div>
</a>
```

### Paso 9 — Verificación final

```bash
# Frontend accesible
curl -s -H "Host: <dominio>.casa" http://192.168.1.55/ | head -3

# API (si aplica)
curl -s http://localhost:<puerto-backend>/health

# DNS desde otro dispositivo de la red
# (desde maya usar la IP directa porque nsswitch.conf interfiere)
```

---

## Checklists rápidos

### Deploy solo frontend
- [ ] `npm install` + build
- [ ] Copiar dist a `/mnt/nas/webs/<dominio>.casa/`
- [ ] Nginx site + reload
- [ ] DNS en pihole1 y pihole2 (`dnsmasq.d/local.conf` + restart pihole-FTL)
- [ ] `/etc/hosts` en maya
- [ ] Card en portal.casa

### Deploy frontend + backend Node.js
- Todo lo anterior, más:
- [ ] `.env` con puerto libre (ver tabla de puertos)
- [ ] `npm run build` en backend
- [ ] Copiar assets estáticos a dist (`openapi.yaml`, etc.)
- [ ] Systemd service con entry point `dist/src/server.js`
- [ ] `sudo systemctl enable --now <proyecto>`
- [ ] Proxy `/api/` en nginx apuntando al puerto del backend

---

## Actualizar un despliegue existente

```bash
# 1. Recompilar frontend
cd /mnt/nas/sources/<proyecto>/frontend && node_modules/.bin/ng build --configuration production

# 2. Sincronizar a producción
cp -r dist/<nombre>/browser/. /mnt/nas/webs/<dominio>.casa/

# 3. Si hay backend: recompilar y reiniciar
cd /mnt/nas/sources/<proyecto>/backend && npm run build
cp -r src/openapi dist/src/openapi   # assets estáticos
sudo systemctl restart <proyecto>
```

No hace falta tocar nginx, DNS ni portal.casa en actualizaciones.
