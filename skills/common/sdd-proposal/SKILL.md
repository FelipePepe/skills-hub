---
name: sdd-proposal
description: >
  Alias legacy de compatibilidad para la fase de propuesta de SDD.
  Trigger: solo cuando exista una referencia antigua a `sdd-proposal`; en flujo nuevo usar `sdd-propose`.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "3.0"
---

# 🛡️ Execution Contract: sdd-proposal

## 🎯 Intent
Legacy compatibility alias. This skill forwards all logic to `sdd-propose`.

## 🔍 Pre-conditions (Invariant Check)
*   [ ] This skill should NEVER be invoked in a new workflow.
*   [ ] If invoked, it MUST load and delegate to `skills/common/sdd-propose/SKILL.md`.

## ⚙️ Execution Logic (Deterministic Steps)
1.  **[Phase: Alias Resolve]** Load `sdd-propose` and execute its logic.
2.  **[Phase: Compatibility Return]** Return results with `sdd-propose` format, but acknowledge legacy naming if required by context.

## 🏁 Post-conditions (Guarante 💎)
*   [ ] Result is identical to `sdd-propose`.
*   [ ] No new references to this skill are created.
*   [ ] Documentation is updated to point to `sdd-propose`.

## ⚠️ Failure Modes & Recovery
*   **IF** this skill is called in a new workflow **THEN** alert and suggest using `sdd-propose`.

## 🛠️ Traceability (Inputs/Outputs)
*   **Inputs:** `change-name` | `exploration` | `mode` | `existing-specs`
*   **Outputs:** `proposal.md` | `capabilities-list` | `summary`
