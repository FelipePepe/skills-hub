---
name: mente-docs
description: >
  Crea y actualiza documentos en el vault de Mente (Obsidian) en la intranet .casa.
  Garantiza que todos los documentos tengan wikilinks bidireccionales para el grafo de conocimiento.
  Trigger: Cuando el usuario pide crear o actualizar documentos en mente.casa, el vault Obsidian,
  o cuando se implementa algo nuevo en la intranet que debe quedar documentado.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---

## When to Use

- El usuario dice "actualiza los documentos de mente.casa" o "documenta esto en mente"
- Se acaba de implementar algo nuevo en la intranet (nuevo servicio, dominio, feature)
- El usuario pide crear una nueva nota en el vault
- Se detecta que una nota no tiene enlaces a otras notas relacionadas
- Se pregunta por el estado de la documentación

## Infraestructura del Vault

| Dato | Valor |
|------|-------|
| **Máquina** | pihole2 — `192.168.1.54` |
| **Ruta vault** | `/home/sandman/Obsidian/` |
| **Usuario SSH** | `felipe` (usa `sudo tee` para escribir como `sandman`) |
| **App** | `mente.casa` (React + obsidian-api backend) |

### Estructura de carpetas

```
/home/sandman/Obsidian/
├── Stack/
│   ├── _INDEX.md          ← Índice maestro de todo el vault
│   ├── AI-ML/             ← LangChain, Ollama, CrewAI, RAG, Whisper, Vosk...
│   ├── Auth/              ← JWT, BcryptJS, TOTP-2FA
│   ├── Backend/           ← Express, FastAPI, SpringBoot, Hono, Kafka
│   ├── Databases/         ← PostgreSQL, SQLite, MySQL, ChromaDB
│   ├── DevOps/            ← Docker, GitHubActions, Prometheus, Grafana...
│   ├── Frontend/          ← React, Angular, NextJS, Vite, TailwindCSS...
│   ├── Languages/         ← TypeScript, Python, Go, Java, Rust, Kotlin...
│   ├── ORM/               ← DrizzleORM, SpringDataJPA
│   ├── Testing/           ← Vitest, Playwright, Pytest, JUnit
│   └── Tools/             ← ESLint, Prettier, Zod, Swagger, Drizzle-Kit
├── Proyectos/             ← Notas de proyectos concretos
└── Setup/                 ← Infraestructura, dispositivos, servicios
    ├── _INDEX.md (o red en Red-Local-Servicios.md)
    ├── Dispositivos.md
    ├── Red-Local-Servicios.md
    ├── Agent-Skills.md
    ├── Syncthing-RPi.md
    ├── Dropbox-Sync.md
    └── KDE-Connect.md
```

## Reglas de Wikilinks — CRÍTICO

Obsidian resuelve wikilinks por **nombre de archivo** (sin ruta, sin `.md`).

```markdown
[[NombreNota]]                          ← enlace simple
[[NombreNota|Texto visible]]            ← enlace con alias
[[CarpetaExplicita/NombreNota|Alias]]   ← enlace con ruta (para ambigüedad)
```

### Reglas obligatorias

1. **Todo documento debe tener al menos 2 wikilinks** a otros documentos del vault
2. **Los enlaces deben ser bidireccionales**: si A enlaza a B, B debe enlazar a A
3. **Sección "## Ver también"** al final de TODA nota — siempre
4. **Stack notes**: incluir "## Stack relacionado" con tecnologías hermanas
5. **Proyectos**: enlazar a las tecnologías del Stack que usan
6. **Setup**: enlazarse entre sí (Dispositivos ↔ Red-Local-Servicios ↔ Proyectos relevantes)
7. **`Stack/_INDEX.md`**: actualizar cuando se añade una nota nueva

### Nombres de archivo exactos (para wikilinks correctos)

Los nombres de los archivos sin extensión son los identifiers:

**Stack/Frontend:** React, Angular, AngularMaterial, NextJS, Vite, TailwindCSS, RadixUI, ShadcnUI, TanStackQuery, FramerMotion, Recharts  
**Stack/Backend:** ExpressJS, FastAPI, SpringBoot, Hono, Kafka  
**Stack/Languages:** TypeScript, Python, Go, Java, JavaScript, CSharp, Rust, Kotlin  
**Stack/AI-ML:** LangChain, LangGraph, LangSmith, CrewAI, Ollama, PyTorch, MCP, RAG, Whisper, Vosk  
**Stack/Databases:** PostgreSQL, SQLite, MySQL, ChromaDB  
**Stack/ORM:** DrizzleORM, SpringDataJPA  
**Stack/Testing:** Vitest, Playwright, Pytest, JUnit  
**Stack/Auth:** JWT, BcryptJS, TOTP-2FA  
**Stack/DevOps:** Docker, GitHubActions, Prometheus, Grafana, Vercel, SonarQube  
**Stack/Tools:** ESLint, Prettier, Zod, Swagger, Drizzle-Kit  
**Setup:** Dispositivos, Red-Local-Servicios, Agent-Skills, Syncthing-RPi, Dropbox-Sync, KDE-Connect  
**Proyectos:** obsidian-clone (Mente), netscan, dotnet-cache-poc, dotnet-framework-cache-evolution

## Protocolo de Trabajo

### Paso 1 — Descubrir estado actual
```bash
ssh felipe@192.168.1.54 "find /home/sandman/Obsidian -name '*.md' | sort"
ssh felipe@192.168.1.54 "grep -r '\[\[' /home/sandman/Obsidian/Setup/ --include='*.md' -l"
```

### Paso 2 — Auditar enlaces faltantes
Para cada nota a crear/actualizar, identificar:
- ¿Qué otras notas del vault la mencionan o deberían mencionarla?
- ¿Tiene sección "## Ver también"?
- ¿Está en `_INDEX.md`?

### Paso 3 — Escribir/actualizar notas
```bash
# Siempre con sudo tee (los archivos son de sandman, nos conectamos como felipe)
ssh felipe@192.168.1.54 'sudo tee /home/sandman/Obsidian/CARPETA/Nota.md > /dev/null << '"'"'EOF'"'"'
[contenido markdown con wikilinks]
EOF
echo "OK"'
```

### Paso 4 — Actualizar notas que deben enlazar a la nueva
Si creas `Proyectos/nueva-herramienta.md` que usa React y TypeScript:
- Actualizar `Stack/Frontend/React.md` → añadir en "## Proyectos que lo usan"
- Actualizar `Stack/Languages/TypeScript.md` → idem
- Actualizar `Stack/_INDEX.md` → añadir en sección Proyectos

### Paso 5 — Verificar en mente.casa
```bash
curl -s http://mente.casa/api/notes | python3 -c "import json,sys; notes=json.load(sys.stdin); print(f'{len(notes)} notas en el vault')"
```

## Templates

### Template: Stack Note

```markdown
# {Nombre}

> {Descripción en una línea}. Usado con [[{Relacionado1}]] y [[{Relacionado2}]].

## ¿Qué es?
{Descripción de 2-3 líneas. Incluir al menos 2 wikilinks a tecnologías relacionadas.}

## Stack relacionado
[[Tech1]] · [[Tech2]] · [[Tech3]]

## Instalación
```bash
{comando de instalación}
```

## Uso básico
```{lang}
{ejemplo mínimo funcional}
```

## Proyectos que lo usan
- [[Proyectos/nombre-proyecto|Nombre Proyecto]] — {cómo se usa}

## Ver también
- [[TecnologíaRelacionada1]] — {relación}
- [[TecnologíaRelacionada2]] — {relación}
- [[Red-Local-Servicios]] — {solo si aplica a la intranet}
```

### Template: Proyecto Note

```markdown
# {Nombre Proyecto}

**Última actualización:** {YYYY-MM-DD}

## Descripción
{Qué hace el proyecto. Enlazar tecnologías del stack usadas.}

## Stack

| Capa | Tecnología |
|------|-----------|
| Frontend | [[React]], [[Vite]], [[TypeScript]] |
| Backend | [[ExpressJS\|Express]], [[TypeScript]] |
| ...

## Arquitectura
```
{diagrama ASCII o descripción}
```

## Estado del proyecto
- [x] Feature 1
- [ ] Feature 2 (pendiente)

## Deploy
```bash
{comandos de deploy}
```

## Ver también
- [[Red-Local-Servicios]] — configuración nginx
- [[Dispositivos]] — máquinas involucradas
- [[Stack relacionado]] — tecnologías usadas
```

### Template: Setup Note

```markdown
# {Servicio/Config}

**Última actualización:** {YYYY-MM-DD}

## Descripción
{Qué es y para qué sirve en la intranet.}

## Infraestructura

| Dato | Valor |
|------|-------|
| Máquina | [[Dispositivos\|pihole2]] (192.168.1.54) |
| Dominio | `servicio.casa` |
| ...

## Configuración
{detalles}

## Comandos útiles
```bash
{comandos}
```

## Ver también
- [[Dispositivos]] — inventario de la red
- [[Red-Local-Servicios]] — configuración nginx
- [[Proyectos/proyecto-relacionado]] — {si aplica}
```

## Convenciones de Fechas y Formato

- Fecha: `**Última actualización:** YYYY-MM-DD`
- Encabezado H1 obligatorio en cada nota
- Tablas para datos estructurados (inventarios, endpoints, comandos)
- Bloques de código con lenguaje especificado (` ```bash `, ` ```tsx `, etc.)
- Emojis opcionales en títulos de sección (solo en `_INDEX.md`)

## Dominios .casa actuales (para referencias en notas)

| Dominio | Servicio | Máquina |
|---------|---------|---------|
| `mente.casa` | App de notas (Mente) | pihole2 |
| `obsidian.casa` | Alias legacy Mente | pihole2 |
| `portal.casa` | Dashboard intranet | pihole2 |
| `ha.casa` | Home Assistant | pihole2 |
| `nas.casa` | FileBrowser NAS | maya |
| `maya.casa` | Equipo maya | maya |
| `pihole2.casa` | Panel Pi-hole 2 | pihole2 |
| `pihole1.casa` | Panel Pi-hole 1 | pihole1 |
| `clockwork.casa` | clockworkpi | clockwork |
| `router.casa` | Router | 192.168.1.1 |
