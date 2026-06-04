---
name: session-start
description: >
  Activa el workflow de sesión: detecta el proyecto activo, comprueba estado git,
  lee el último journal y docs de estado, detecta spec activa con tareas pendientes,
  consulta contexto en Engram y Atlas, y opcionalmente ejecuta tests/benchmark rápidos.
  Devuelve un briefing de retomada con sugerencias de próximo paso. Trigger: el
  usuario dice "empezamos sesión", "session start", "retomamos", "dónde lo dejamos",
  "estado del proyecto", "ponme al día", "inicio de sesión".
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## Cuándo usar este skill

- El usuario abre una sesión nueva en un proyecto y quiere retomar contexto
- El usuario dice "dónde lo dejamos", "ponme al día", "estado del proyecto"
- Después de varios días sin tocar un proyecto, al volver a él
- Antes de empezar a programar en un repo no trivial

NO usar si:
- El usuario pregunta algo concreto que NO requiere recargar contexto del proyecto
- Ya se ha hecho session-start en esta misma sesión

---

## Protocolo de arranque

Ejecutar los pasos en este orden. **Paralelizar** las llamadas independientes en un mismo turno (git + reads + mem_context + atlas_search son todas independientes).

### Paso 1 — Detectar el proyecto activo

- `pwd` y buscar marcadores de proyecto: `.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`
- Si hay `CLAUDE.md` en el directorio: leerlo (políticas, convenciones, venv, comandos)
- Si hay `CLAUDE.md` en `~/.claude/`: ya está cargado automáticamente — no releer
- Nombre canónico del proyecto = nombre del directorio o `package.json::name`/`pyproject.toml::project.name`

### Paso 2 — Estado git

Ejecutar en paralelo en un único turno:

- `git status --short` (cambios sin commitear)
- `git branch --show-current` + `git log --oneline -5` (rama + últimos 5 commits)
- `git stash list` (stashes pendientes)

Si hay cambios sin commitear o stashes → señalarlos en el briefing.

### Paso 3 — Documentación de estado

Leer si existen (en orden, sin fallar si alguno falta):

1. `docs/journal/sessions/` — última entrada por fecha
2. `docs/STATE.md` — snapshot ejecutivo
3. `IMPLEMENTATION_SUMMARY.md` — capacidades y estado de specs
4. `README.md` — solo si los anteriores no existen

### Paso 4 — Spec activa (si el proyecto sigue SDD)

- Buscar `specs/NNN-*/tasks.md` (orden numérico descendente — la última suele ser la activa)
- Para cada spec, contar checkboxes `- [ ]` (pendientes) vs `- [x]` (cerrados)
- Spec activa = la última cuyo ratio de pendientes > 0 **Y** cuya última edición es reciente

CUIDADO: checkboxes sin marcar pueden ser obsoletos. Cruza con `IMPLEMENTATION_SUMMARY.md` o el journal antes de afirmar "spec X tiene Y pendientes". Si el resumen dice "cerrada" y los checkboxes están sin marcar → reportar el conflicto, no asumir que está abierta.

### Paso 5 — Memoria persistente

Ejecutar en paralelo:

- `mem_context(project=<nombre>, limit=20)` — observaciones recientes en Engram.
- Lectura directa del vault **Atlas (Obsidian)** en `/mnt/nas/Obsidian/`:
  - `Proyectos/<nombre>.md` — entity page del proyecto, si existe (estado arquitectónico).
  - Si el MCP `atlas_search` está disponible, úsalo además. Si no, `grep`/`find` en el vault.

Cruzar fechas:
- Si la última observación de Engram es más antigua que el último journal → señalar "Engram desactualizado, hay drift de N días".
- Si `Proyectos/<nombre>.md` tiene `Última actualización:` anterior al último journal del proyecto → señalar drift de Atlas en el briefing (es trabajo de `session-end` reconciliarlo).

### Paso 6 — Tests/benchmark rápidos (opcional, preguntar primero)

NO ejecutar automáticamente. Preguntar al usuario:

> "¿Ejecuto tests + benchmark como sanity check? (puede tardar ~30s-2min)"

Si responde sí:
- Detectar comando de tests desde `CLAUDE.md` del proyecto o convenciones (`pytest`, `npm test`, `go test ./...`, `cargo test`, `unittest discover -s tests`)
- Respetar venvs y rutas documentadas en `CLAUDE.md` (e.g. vi-sdd usa `/home/sandman/.venvs/vi-sdd/bin/python`)
- Reportar verde/rojo + número de tests; si rojo, NO intentar arreglar — solo señalar

### Paso 7 — Briefing al usuario

Devolver un resumen estructurado:

```
## Punto de retomada — <proyecto>

**Rama:** <branch> · **Último commit:** <hash> <msg>
**Cambios sin commitear:** <N archivos> | <ninguno>
**Última sesión:** <fecha del journal> — <título o primera línea>

### Estado del proyecto
- <bullet con métricas clave de STATE/IMPLEMENTATION_SUMMARY>
- <bullet con spec activa si la hay>

### Deuda priorizada (top 3)
- <de STATE.md §deuda o IMPLEMENTATION_SUMMARY>

### Sugerencia de próximo paso
<1-2 frases concretas basadas en el último journal y las tareas pendientes>
```

Si hay conflictos detectados (engram desactualizado, checkboxes vs IMPLEMENTATION_SUMMARY, tests rojos), añadir sección **⚠ Atención** con el detalle.

---

## Reglas operativas

- **No escribir nada en disco** durante session-start. Solo lectura.
- **No modificar memorias** (engram/atlas) en start — eso es trabajo de `session-end`.
- **Paralelizar lecturas** siempre que sea posible. Bash + Read + mem_context + atlas_search pueden ir en el mismo turno.
- **Fallar grácil**: si engram, atlas, o algún archivo no responde/existe → omitir esa sección del briefing, no romper el flujo.
- **Respeta idioma del proyecto**: si CLAUDE.md indica español (como vi-sdd, homelab), el briefing va en español. Inglés por defecto.
- **No sugerir cambios de código** en el briefing. La sugerencia de próximo paso es "qué tarea atacar", no "qué línea editar".

---

## Heurísticas

**¿Hay spec activa?**
- Existe `specs/NNN-*/tasks.md` con `- [ ]` pendientes Y el journal/STATE no dice explícitamente "cerrada" → sí
- Si `IMPLEMENTATION_SUMMARY.md` dice "cerrada el <fecha>" y los checkboxes están sin marcar → checkboxes obsoletos, NO hay spec activa

**¿Engram desactualizado?**
- Última observación con `project=<X>` > 7 días antes del último journal → desactualizado
- Sugerir al final del briefing: "Considera ejecutar `/session-end` al final de hoy para sincronizar Engram"

**¿Atlas relevante?**
- El vault Atlas vive en `/mnt/nas/Obsidian/`. Estructura: `Proyectos/<proyecto>.md` (entity page), `Stack/<categoría>/<tech>.md` (catálogo tech con `_INDEX.md`), `Setup/` (infra), `AI/`, `Temp/`.
- Si `Proyectos/<proyecto>.md` existe → leerlo siempre: tiene estado arquitectónico estable + backlinks a tecnologías del Stack relevantes.
- Para proyectos personales pequeños sin entity page, omitir.

---

## Ejemplo de salida (vi-sdd, simulado)

```
## Punto de retomada — vi-sdd

**Rama:** main · **Último commit:** abc1234 chore: close spec 006
**Cambios sin commitear:** 12 archivos sin trackear (.artifacts/, .claude/, CLAUDE.md, docs/, specs/, src/, tests/)
**Última sesión:** 2026-05-21 — Cierre spec 006 (OWASP coverage). Macro F1 0.998, 317 tests.

### Estado del proyecto
- 6 specs cerradas (001→006). Pipeline 6 etapas: prepare→scan→validate→dedup→prove→report.
- Macro F1 0.998, 0 FPs, 7 categorías OWASP cubiertas. Última métrica récord.
- No hay spec activa con phases pendientes.

### Deuda priorizada (top 3)
- Calibrar auditor LLM (qwen2.5-coder:7b alucina; F1 con auditor cae a 0.76)
- Fixtures CVE OSS reales (Heartbleed, getaddrinfo) — spec 004 phase 10.1
- A01 Django/Spring handler collectors (framework detectado, handlers no recolectados)

### Sugerencia de próximo paso
Si quieres seguir trabajando: abrir spec 007 extendiendo A07/A10 a Java/C#/Go/Rust, o sesión iterativa de calibración auditor (1-2h). Si el objetivo es consolidar: commit del estado actual (hay docs/, specs/, src/ sin trackear).

⚠ Engram estaba desactualizado al 2026-05-18 — sincronizado en la sesión previa. OK.
```
