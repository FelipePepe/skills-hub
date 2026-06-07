---
name: nueva-casa
description: >
  Registra un servicio ya existente en la intranet .casa: añade DNS en ambos
  Pi-holes, crea la config nginx en maya (reverse proxy o estático) y añade la
  card en portal.casa. Sin compilación — para servicios que ya corren en algún
  puerto o IP de la red. Trigger: "añade X a la intranet", "crea el dominio
  X.casa", "apunta X.casa a este puerto", "registra el servicio en portal".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## Cuándo usar este skill

- Hay un servicio corriendo (Docker, Node, Python…) y se quiere acceder por `nombre.casa`
- Se quiere añadir un alias `.casa` para una IP/puerto existente
- `deploy-casa` es excesivo porque no hay nada que compilar ni desplegar

---

## Información necesaria antes de empezar

1. **Nombre del dominio**: `<nombre>.casa`
2. **IP destino**: ¿en qué máquina corre? (maya=192.168.1.55, pihole2=192.168.1.54…)
3. **Puerto**: si es reverse proxy, ¿en qué puerto escucha el servicio?
4. **Tipo nginx**: reverse proxy a un puerto / servir ficheros estáticos ya existentes
5. **Descripción y emoji** para la card en portal.casa

---

## Infraestructura de referencia

| Máquina | IP | Nginx |
|---------|----|-------|
| maya | 192.168.1.55 | `/etc/nginx/sites-available/` |
| pihole2 | 192.168.1.54 | SSH + nginx |

**DNS**: `/etc/dnsmasq.d/local.conf` en pihole1 (192.168.1.53) y pihole2 (192.168.1.54)

---

## Paso 1 — DNS en ambos Pi-holes

```bash
for host in 192.168.1.53 192.168.1.54; do
  ssh $host "echo 'address=/<nombre>.casa/<IP-destino>' \
    | sudo tee -a /etc/dnsmasq.d/local.conf \
    && sudo systemctl restart pihole-FTL \
    && echo ok"
done
```

> ⚠️ Usar siempre `dnsmasq.d/local.conf`. NO usar `/etc/pihole/custom.list`.

---

## Paso 2 — Nginx en la máquina destino

### Caso A: Reverse proxy (servicio en un puerto local)

En `/etc/nginx/sites-available/<nombre>.casa` (en maya o via SSH si está en pihole2):

```nginx
server {
    listen 80;
    server_name <nombre>.casa;

    location / {
        proxy_pass http://127.0.0.1:<puerto>;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Caso B: Ficheros estáticos en NAS

```nginx
server {
    listen 80;
    server_name <nombre>.casa;

    root /mnt/nas/webs/<nombre>.casa;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Activar y recargar

```bash
# En maya:
sudo ln -sf /etc/nginx/sites-available/<nombre>.casa /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# En pihole2 (via SSH):
ssh 192.168.1.54 "sudo ln -sf /etc/nginx/sites-available/<nombre>.casa /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx"
```

---

## Paso 3 — /etc/hosts en maya

```bash
echo "<IP-destino> <nombre>.casa" | sudo tee -a /etc/hosts
```

> ⚠️ Obligatorio para que maya misma resuelva el dominio (`mdns4_minimal` en nsswitch.conf bloquea el DNS para `.casa`).

---

## Paso 4 — Card en portal.casa

Editar `/mnt/nas/webs/portal.casa/index.html`:

1. Incrementar el badge de la sección correspondiente (`Servicios`, `Infraestructura`, etc.)
2. Insertar antes del cierre `</div></div>` de esa sección:

```html
<a class="card" href="http://<nombre>.casa" data-check="http://<nombre>.casa" data-name="<keywords búsqueda>">
  <div class="card-top"><div class="card-icon"><emoji></div><div class="dot checking"></div></div>
  <div class="card-name"><Nombre visible></div>
  <div class="card-desc"><Descripción breve.></div>
  <div class="card-meta"><span class="card-url"><nombre>.casa</span><span class="badge"><máquina-host></span></div>
</a>
```

**Secciones disponibles en portal.casa**: `Servicios`, `Infraestructura`, `Máquinas`

---

## Paso 5 — Verificación

```bash
# DNS resuelve en Pi-holes
ssh 192.168.1.53 "nslookup <nombre>.casa 127.0.0.1 2>/dev/null | grep Address | tail -1"

# Nginx responde (bypasando DNS de maya con Host header)
curl -s -H "Host: <nombre>.casa" http://<IP-destino>/ | head -3

# Card en portal
curl -s http://portal.casa | grep -o '<nombre>.casa'
```

---

## Dominios .casa actuales (referencia)

| Dominio | IP | Máquina | Tipo |
|---------|----|---------|------|
| portal.casa | 192.168.1.54 | pihole2 | estático NAS |
| ha.casa | 192.168.1.54 | pihole2 | reverse proxy |
| atlas.casa | 192.168.1.54 | pihole2 | reverse proxy |
| oficina.casa | 192.168.1.54 | pihole2 | estático NAS |
| nas.casa | 192.168.1.54 | pihole2 | reverse proxy |
| trello.casa | 192.168.1.55 | maya | estático NAS + proxy API |
| maya.casa | 192.168.1.55 | maya | estático |
