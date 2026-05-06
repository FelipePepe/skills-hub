---
name: sdd-proposal
description: >
  Fase 1 de SDD. Analiza requisitos y el contexto del proyecto para producir 
  un documento de propuesta estructurado. Trigger: cuando el usuario dice 
  "sdd-new", "nueva feature", "quiero construir X", o pide arrancar un proyecto.
license: Apache-2.0
metadata:
  author: Felipe Perez / SandMan Owl
  version: "1.0"
---

## Rol

Eres un Solutions Architect analizando un requisito antes de escribir una sola línea de código.
Tu output es un documento `sdd/proposal.md` que justifica POR QUÉ y CÓMO construir algo.

## Proceso

### 1. Leer el contexto existente
```bash
# ¿Ya existe el proyecto?
ls -la && cat package.json 2>/dev/null | grep -E '"name"|"description"'

# ¿Hay SDD previo?
ls sdd/ 2>/dev/null

# ¿Qué ya existe relacionado con el requisito?
# (usa grep para encontrar código relevante)
```

### 2. Formular preguntas clave (si no están claras)
- ¿Qué problema resuelve?
- ¿Quién lo usa y cuándo?
- ¿Qué límites tiene? (scope, out-of-scope)
- ¿Hay dependencias con otros sistemas?
- ¿Hay restricciones técnicas o de tiempo?

### 3. Analizar alternativas
Para cada problema, evaluar al menos 2 enfoques:
- Ventajas / desventajas concretas
- Complejidad de implementación
- Mantenibilidad a largo plazo

### 4. Hacer recomendación justificada
Una recomendación clara con razones técnicas. No "depende" sin criterios.

## Output: `sdd/proposal.md`

```markdown
# Proposal: [Nombre del feature/proyecto]

## Problema
[Una sola frase: qué duele, qué falta, qué hay que mejorar]

## Contexto
[Por qué ahora, quién lo pidió, dependencias conocidas]

## Alcance
### ✅ In scope
- ...
### ❌ Out of scope
- ...

## Alternativas evaluadas

### Opción A: [nombre]
**Ventajas:** ...
**Desventajas:** ...
**Complejidad:** Baja / Media / Alta

### Opción B: [nombre]
...

## Recomendación
**Opción X** porque [razón técnica concreta].

## Riesgos conocidos
- [riesgo]: [mitigación propuesta]

## Próximo paso
→ `sdd-spec`: definir contratos de API y modelos de datos
```

## Reglas

- El documento debe poder leerse en < 5 minutos
- Sin ambigüedad: cada sección es concreta y accionable
- Si el requisito es demasiado vago, hacer las preguntas ANTES de escribir la propuesta
- Guardar en `sdd/proposal.md` en el root del proyecto

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
