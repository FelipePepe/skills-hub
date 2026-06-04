---
name: sdd-proposal
description: >
  Alias legacy de compatibilidad para la fase de propuesta de SDD.
  Trigger: solo cuando exista una referencia antigua a `sdd-proposal`; en flujo nuevo usar `sdd-propose`.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.1"
---

## Estado

Esta skill es un alias legacy.

- **Skill canónica**: `sdd-propose`
- **Usar esta skill solo** si un prompt antiguo, script o documentación legacy la menciona de forma explícita
- **No** crear nuevas referencias a `sdd-proposal`

## Qué hacer

1. Carga y sigue `skills/copilot-only/sdd-propose/SKILL.md`
2. Mantén compatibilidad de nombre en el resumen si el contexto legacy lo requiere
3. Devuelve el resultado con el formato y persistencia definidos por `sdd-propose`

## Reglas

- Tratar `sdd-propose` como la fuente de verdad
- No divergir en formato, persistencia ni contrato
- Si actualizas documentación, sustituye `sdd-proposal` por `sdd-propose`

## Output contract

Follow the output contract of `sdd-propose` exactly. No additional prose.
