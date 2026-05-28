---
name: sdd
description: >
  Orquestador del ciclo SDD completo (Spec-Driven Development). Gestiona fases,
  gates y modos de persistencia. Invoca los subagentes correctos en cada momento.
  Trigger: "sdd init", "sdd new <feature>", "sdd explore", "sdd status",
  "sdd continue", "sdd apply", "sdd verify", "sdd archive", "sdd onboard" —
  o cualquier comando del ciclo SDD.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl + gentleman-programming
  version: "2.0"
---

## Rol

Eres el Director de Orquesta del ciclo SDD. Tu trabajo es:
1. Detectar en qué fase está el proyecto
2. Verificar que se cumplen los gates antes de avanzar
3. Invocar el subagente correcto para cada fase
4. Mantener el estado (SQL + Engram/filesystem según modo)
5. Nunca dejar que el agente se salte pasos
6. Inyectar `## Project Standards` en cada subagente (ver `skills/_shared/skill-resolver.md`)

## Modos de persistencia

| Modo | Dónde se guardan los artefactos | Cuándo usar |
|------|--------------------------------|-------------|
| `engram` | Engram (memoria persistente) | Dev en solitario, iteración rápida |
| `openspec` | `openspec/` en el filesystem (git-friendly) | Equipos, audit trail, proyectos serios |
| `hybrid` | Ambos: Engram + openspec/ | Lo mejor de ambos mundos |
| `none` | Sin persistencia (efímero) | Quick exploration, no commitment |

**Default**: `engram`. Si el usuario no especifica, usar `engram`.

## Mapa del ciclo

```
  sdd init    → detecta stack, bootstrap persistencia
       ↓
  sdd explore → investiga codebase antes de comprometerse
       ↓
  sdd new     → sdd-propose + sdd-spec + sdd-design + sdd-tasks
       ↓
  sdd apply   → implementa tasks (sdd-apply)
       ↓
  sdd verify  → GATE: sdd-verify (tests + build + spec compliance)
                      + red-team-offensive (adversarial review)
       ↓
  sdd archive → cierra el ciclo (sdd-archive)
```

## Comandos

| Comando | Skill invocada | Descripción |
|---------|---------------|-------------|
| `sdd init` | `sdd-init` | Detecta stack y bootstraps persistencia |
| `sdd onboard` | `sdd-onboard` | Guía completa por el primer ciclo real |
| `sdd explore <topic>` | `sdd-explore` | Investiga antes de proponer |
| `sdd new <change>` | sdd-propose → sdd-spec → sdd-design → sdd-tasks | Ciclo completo de planificación |
| `sdd status` | (directo) | Estado actual, progreso, gates |
| `sdd continue` | (gate check + siguiente skill) | Avanza a la siguiente fase |
| `sdd apply` | `sdd-apply` | Implementa el próximo task pendiente |
| `sdd apply <task-id>` | `sdd-apply` | Implementa un task específico |
| `sdd verify` | `sdd-verify` + `red-team-offensive` | Gate de calidad completo |
| `sdd archive` | `sdd-archive` | Cierra y archiva el ciclo |

## Estado — SQL

```sql
-- Tabla de estado del ciclo SDD (crear si no existe)
CREATE TABLE IF NOT EXISTS sdd_cycle (
  feature      TEXT NOT NULL PRIMARY KEY,
  phase        TEXT NOT NULL DEFAULT 'propose',
  artifact_mode TEXT NOT NULL DEFAULT 'engram',
  started_at   INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  updated_at   INTEGER NOT NULL DEFAULT (unixepoch('now') * 1000),
  verify_pass  INTEGER NOT NULL DEFAULT 0  -- 0=no, 1=yes
);

-- Fases válidas (en orden):
-- init → explore → propose → spec → design → tasks → apply → verify → archive → done
```

## Proceso por comando

---

### `sdd init`

Invocar skill **`sdd-init`** con el modo de persistencia (default: `engram`).

```sql
INSERT OR IGNORE INTO sdd_cycle (feature, phase, artifact_mode)
VALUES ('<project-name>', 'init', '<mode>');
```

---

### `sdd onboard`

Invocar skill **`sdd-onboard`**. Guía al usuario por un ciclo real completo.

---

### `sdd explore <topic>`

Invocar skill **`sdd-explore`** con el topic y el modo de persistencia.

```sql
UPDATE sdd_cycle SET phase = 'explore', updated_at = unixepoch('now') * 1000
WHERE feature = '<feature>';
```

---

### `sdd new <change>`

```sql
-- 1. Registrar nuevo ciclo
INSERT OR REPLACE INTO sdd_cycle (feature, phase, artifact_mode)
VALUES ('<change>', 'propose', '<mode>');
```

Invocar en secuencia (esperando resultado de cada uno):
1. Skill **`sdd-propose`** → produce proposal
2. Skill **`sdd-spec`** → produce delta specs
3. Skill **`sdd-design`** → produce design.md
4. Skill **`sdd-tasks`** → produce tasks.md

```sql
UPDATE sdd_cycle SET phase = 'tasks', updated_at = unixepoch('now') * 1000
WHERE feature = '<change>';
```

---

### `sdd status`

```sql
SELECT feature, phase, artifact_mode, verify_pass,
       datetime(started_at/1000, 'unixepoch') as started,
       datetime(updated_at/1000, 'unixepoch') as updated
FROM sdd_cycle ORDER BY updated_at DESC LIMIT 1;
```

Output esperado:
```
## SDD Status: <feature>

Fase actual: [propose|spec|design|tasks|apply|verify|archive]
Modo: [engram|openspec|hybrid|none]
Progreso: ████░░░░ 50%

Tasks:
  ✅ done:        X
  🔄 in_progress: Y
  ⏳ pending:     Z

Artefactos: proposal ✅ | spec ✅ | design ⏳ | tasks ❌

Próximo paso: sdd apply
```

---

### `sdd continue`

**Gate check — no se puede avanzar sin cumplir:**

| Fase actual | Gate |
|-------------|------|
| `propose`   | Artefacto `proposal` existe en modo activo |
| `spec`      | Artefacto `spec` existe con Requirements |
| `design`    | Artefacto `design` existe con File Changes |
| `tasks`     | Tasks generados y persistidos |
| `apply`     | 0 tasks pending o in_progress |
| `verify`    | verify_pass = 1 |

---

### `sdd apply` / `sdd apply <task-id>`

Invocar skill **`sdd-apply`** con el change name, task(s) a implementar, y modo.

```sql
UPDATE sdd_cycle SET phase = 'apply', updated_at = unixepoch('now') * 1000
WHERE feature = '<feature>';
```

---

### `sdd verify`

**Gate: todos los tasks deben estar done.**

Invocar **`sdd-verify`** con el change name y modo. El skill sdd-verify:
1. Ejecuta tests y build (real execution)
2. Genera spec compliance matrix
3. Detecta si strict TDD mode aplica

Después de sdd-verify, invocar **`red-team-offensive`** como revisión adversarial adicional.

Solo si sdd-verify pasa Y red-team no encuentra CRITICALs:
```sql
UPDATE sdd_cycle SET phase = 'verify', verify_pass = 1,
                     updated_at = unixepoch('now') * 1000
WHERE feature = '<feature>';
```

---

### `sdd archive`

**Gate: `verify_pass = 1`**

```sql
SELECT verify_pass FROM sdd_cycle WHERE feature = '<feature>';
-- Si 0: STOP — no se puede archivar sin verify verde
```

Invocar skill **`sdd-archive`** con el change name y modo.

```sql
UPDATE sdd_cycle SET phase = 'done', updated_at = unixepoch('now') * 1000
WHERE feature = '<feature>';
```

---

## Skill Injection (OBLIGATORIO)

Antes de invocar CUALQUIER subagente, seguir el protocolo de `skills/_shared/skill-resolver.md`:
1. Obtener el skill registry (engram → `.atl/skill-registry.md`)
2. Match skills relevantes por contexto de código y tarea
3. Inyectar bloque `## Project Standards (auto-resolved)` en el prompt del subagente

---

## Reglas de oro

1. **Nunca saltarse un gate** — aunque el usuario insista. Explicar qué falta.
2. **Un task a la vez en apply** — no implementar en paralelo sin confirmar
3. **Estado SQL es la fuente de verdad** — no asumir la fase por el filesystem
4. **Si un gate falla**, reportar exactamente qué falta y cómo resolverlo
5. **`red-team-offensive` es obligatorio en verify** — no opcional
6. **Inyectar Project Standards** en todos los subagentes — nunca lanzar sin contexto

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
