---
name: session-end
description: >
  Cierre estructurado de sesión: revisa el trabajo realizado, separa lo
  operativo (Engram) de lo arquitectónico estable (Atlas), busca duplicados antes
  de guardar, persiste cada observación en formato canónico, y opcionalmente
  añade entrada al journal del proyecto. Trigger: el usuario dice "cierra la
  sesión", "fin de sesión", "guarda en engram", "guarda contexto", "resume lo
  que hemos hecho", "qué guardamos de esta sesión", o al final de una sesión
  de trabajo larga. Reemplaza a la antigua `engram-fin-sesion`.
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## Cuándo usar este skill

- El usuario pide explícitamente cerrar/guardar al final de una sesión
- Se ha realizado trabajo significativo (deploy, feature, bugfix, decisión arquitectónica)
- El usuario dice "cerramos por hoy", "guarda lo importante", "resume la sesión"
- Se detectan decisiones/aprendizajes que no están en memoria persistente

NO usar si:
- La sesión ha sido trivial (un typo, una pregunta sin código)
- Ya se ejecutó session-end en este mismo turno

---

## Protocolo de cierre

### Paso 1 — Revisar el historial de la sesión

Recorrer la conversación e identificar candidatos. Por cada uno, decidir tipo:

| Tipo | Guardar si... |
|------|--------------|
| `decision` | Decisión de arquitectura/tecnología/enfoque no obvia |
| `bugfix` | Error resuelto — síntoma, causa raíz, fix |
| `architecture` | Estructura diseñada/documentada (módulo, red, sistema) |
| `pattern` | Convención o forma de trabajar repetible |
| `config` | Configuración del entorno (nginx, systemd, DNS, env vars) |
| `discovery` | Hallazgo no documentado (puerto ocupado, limitación, comportamiento inesperado) |

**No guardar**:
- Pasos obvios o documentados oficialmente
- Código que ya está en el repo (el repo es fuente de verdad)
- Estado temporal (tareas en curso, TODOs sin contexto)
- Cosas ya en Engram/Atlas — verificar primero

### Paso 2 — Clasificar destino: Engram vs Atlas

Cada candidato va a UN destino (no a ambos salvo razón explícita).

**Atlas — conocimiento persistente y arquitectónico** (vida útil >6 meses, cross-session):
- Vive en `/mnt/nas/Obsidian/` (vault Obsidian). Acceso primario vía filesystem (Read/Write/Edit) — el MCP `atlas_*` puede no estar disponible en toda sesión.
- Estructura: `Proyectos/<proyecto>.md` (entity page por proyecto), `Stack/<categoría>/<tech>.md` (referencia tech con `_INDEX.md` maestro), `Setup/` (infra/operacional), `AI/`, `Temp/`.
- Decisiones de arquitectura "load-bearing": elección de stack, modelo de datos, contratos de API estables.
- Convenciones organizacionales que aplican a múltiples proyectos.
- Mapeos canónicos (e.g. "MDASH↔vi-sdd", taxonomías OWASP).
- Patrones de trabajo establecidos a nivel personal/equipo.

**Lo más típico al cierre de sesión**: si hubo cierre de spec/phase con sustancia arquitectónica, **actualizar `Proyectos/<proyecto>.md`** con el delta (estado actual, métricas, links nuevos a Stack tech). No suele ser una página nueva — es un upsert sobre el entity page existente. Convención obligatoria: refrescar el campo `**Última actualización:** YYYY-MM-DD` al inicio.

**Engram — memoria operativa** (vida útil semanas-meses, day-to-day):
- Bugs resueltos (síntoma+causa+fix)
- Estado de specs y métricas (snapshots temporales)
- Configuración de entornos concretos (venv, puertos, paths)
- Deuda técnica priorizada
- Decisiones tácticas dentro de una spec

**Regla rápida**: si la respuesta a "¿esto seguirá siendo cierto en 6 meses?" es SÍ → atlas. Si es "depende del estado actual" → engram.

### Paso 3 — Buscar duplicados antes de guardar

Para cada candidato:

- Engram: `mem_search("<título o keywords>", project=<X>)`. Si existe similar: usar `topic_key` para upsert con `mem_save` o `mem_update`.
- Atlas: comprobar si existe `Proyectos/<proyecto>.md` en `/mnt/nas/Obsidian/`. Si sí → editar la sección relevante (no crear nueva página). Si la observación es transversal a varios proyectos o sobre una tecnología, considerar `Stack/<categoría>/<tech>.md`. Última opción: crear página nueva — solo si el tema realmente no encaja en ninguna existente.

Los `topic_key` (Engram) deben ser estables y compuestos: `vi-sdd/spec-006-owasp`, `homelab/nginx-config`, `personal/git-workflow`.

### Paso 4 — Guardar con estructura canónica

Formato obligatorio para el `content` (engram y atlas):

```
**What**: [qué se hizo o decidió, en una línea]
**Why**: [por qué importa, qué problema resuelve]
**Where**: [rutas, ficheros, comandos, servicios afectados]
**Learned**: [gotchas, edge cases, decisiones tomadas — omitir si no aplica]
```

**Títulos**: cortos, buscables, prefijados por proyecto cuando aplique.
- ✅ `vi-sdd: dedup command-injection-sink (spec 006 phase 8)`
- ✅ `homelab: nginx en pihole2 - reload sin reiniciar`
- ❌ `arreglé un problema con nginx`

**Proyectos frecuentes**: `homelab`, `poc-trello`, `openclaw`, `sdd-office`, `vi-sdd`, `engram`.
**Scope personal** (preferido para infraestructura y patrones que aplican a varios proyectos): `scope: personal`.

Ejecutar guardados en paralelo cuando son independientes (varios `mem_save` en un único turno).

### Paso 5 — Journal del proyecto (si aplica)

Si el proyecto tiene `docs/journal/sessions/` y la sesión fue sustancial (no trivial):

- Comprobar si ya existe entrada para hoy: `docs/journal/sessions/YYYY-MM-DD.md`
- Si NO existe y la sesión justifica entrada: **preguntar al usuario** antes de crearla
  - Plantilla en `docs/journal/sessions/_template.md` si existe
  - Contenido mínimo: objetivo, trabajo realizado, decisiones, bugs encontrados, resultado cuantificado, estado al cierre
- Si ya existe: preguntar si añadir append con los avances de este turno
- NO crear journal automáticamente — siempre confirmar

Si el proyecto NO tiene `docs/journal/` → omitir este paso.

### Paso 6 — Resumen al usuario

Mostrar tabla de lo guardado:

| Destino | Título / Página | Tipo | Acción |
|---------|-----------------|------|--------|
| Engram | ... | bugfix | save |
| Engram | ... | decision | update (#1234) |
| Atlas | `Proyectos/vi-sdd.md` | architecture | edit (sección X) |
| Atlas | `Stack/Languages/Rust.md` | pattern | edit (sección Y) |

Y mencionar brevemente lo que se decidió NO guardar y por qué (e.g. "trivial", "ya estaba en X").

Si se creó/modificó journal: incluir ruta del archivo.

---

## Reglas operativas

- **No inventes** observaciones — solo guarda lo que ocurrió en la conversación.
- **No dupliques** — siempre `mem_search`/`atlas_search` primero. Upsert con `topic_key`.
- **Paralelismo**: guardados independientes van en el mismo turno.
- **Atlas conservador**: por defecto, ante la duda, va a Engram. Solo a Atlas si la decisión es claramente arquitectónica y estable.
- **Respeta idioma del proyecto**: si CLAUDE.md del proyecto está en español, los títulos y contenidos también.
- **No silenciar errores**: si engram/atlas falla, reporta al usuario qué quedó pendiente de guardar.

---

## Heurísticas rápidas

**¿Vale la pena guardar esto?**
- ¿Lo buscarías en memoria la próxima vez que hagas lo mismo? → Sí → guardar
- ¿Tardaste >15 min en resolverlo o entenderlo? → Sí → guardar
- ¿Es algo que podrías olvidar en 2 semanas? → Sí → guardar
- ¿Está ya en el código, CLAUDE.md, o docs/? → No → no guardar

**¿Engram o Atlas?**
- "El catálogo OWASP de vi-sdd mapea 19 bug_classes a 7 categorías" → atlas (taxonomía estable)
- "Spec 006 cerrada el 21-may con F1 0.998 y 317 tests" → engram (snapshot temporal)
- "Para evitar duplicados, dedup de command-injection-sink omite el symbol" → engram (decisión táctica)
- "Usamos arquitectura de pipeline en 6 etapas inspirada en MDASH" → atlas (decisión arquitectónica)

**¿Crear journal?**
- Sesión <30min sin cambios sustanciales → no
- Sesión con bug fix nuevo, decisión, o phase cerrada → sí (preguntar)
- Solo conversación/análisis sin código → no, pero sí actualizar memoria

---

## Compatibilidad

Esta skill **reemplaza** a la antigua `engram-fin-sesion`. Si el usuario invoca esa por nombre, este skill cubre el mismo trigger y añade Atlas + journal.
