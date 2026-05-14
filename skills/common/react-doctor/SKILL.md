---
name: react-doctor
description: >
  Diagnostica problemas y malos patrones en aplicaciones React: render loops,
  efectos mal definidos, estado derivado innecesario, memoización incorrecta,
  componentes demasiado grandes, problemas de hidratación, rendimiento y
  accesibilidad básica. Trigger: cuando el usuario pide revisar una app React,
  depurar comportamiento extraño, auditar performance/renderizado o mejorar la
  salud de componentes React.
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---

## Cuándo usar este skill

- El usuario quiere revisar la salud técnica de una app React
- Hay comportamiento extraño: re-renders, flicker, loops, hydration, stale state
- Se quiere auditar componentes antes de merge o refactor
- Hay dudas sobre hooks, memoización, lifting state, derived state o composición

## Cuándo NO usarlo

- **No** para crear una app nueva desde cero: usar la skill de bootstrap correspondiente
- **No** para bugs puramente de backend, infraestructura o bundling sin relación con React
- **No** para discutir solo estilo visual sin impacto funcional o arquitectónico

---

## Regla de decisión rápida

- Si el problema central es **comportamiento, estructura o rendimiento React** → `react-doctor`
- Si el problema central es **tooling del repo** → `repo-tooling-casa` o equivalente
- Si el problema central es **flujo git/release** → `gitflow-casa` o skill de workflow

Referencia de apoyo:
- `references/checklist.md`

---

## Protocolo de diagnóstico

### Paso 1 — Identificar el síntoma principal

Clasificar el problema en una de estas categorías:
- re-renders excesivos
- `useEffect` mal definido
- estado derivado o duplicado
- memoización inútil o ausente
- componente demasiado grande o acoplado
- hydration / SSR mismatch
- accesibilidad o interacción rota
- cuellos de botella en listas o árboles grandes

### Paso 2 — Leer el componente y su contexto inmediato

Revisar:
- props de entrada
- hooks usados
- dependencias de efectos
- composición padre/hijo
- origen del estado
- side effects

No diagnosticar React mirando una sola línea fuera de contexto.

### Paso 3 — Buscar anti-patrones React

Revisar especialmente:
- `useEffect` que sincroniza estado derivado que podría calcularse en render
- `useEffect` con dependencias incorrectas o inestables
- `useMemo` / `useCallback` añadidos sin beneficio real
- estado local duplicando datos del servidor, props o cache externa
- componentes que hacen demasiadas cosas a la vez
- keys inestables en listas
- lógica de negocio metida en JSX difícil de probar
- handlers recreados en cascada sin necesidad en árboles grandes

### Paso 4 — Priorizar el problema real

Clasificar hallazgos:
- **CRITICAL** → bug funcional, loop, hydration rota, pérdida de datos o UX bloqueada
- **WARNING** → rendimiento pobre, acoplamiento alto, complejidad innecesaria, deuda importante
- **SUGGESTION** → mejora estructural o simplificación no urgente

### Paso 5 — Proponer el tratamiento correcto

Elegir la intervención mínima adecuada:
- eliminar estado derivado y calcular en render
- reducir o corregir un `useEffect`
- mover lógica a hook o función pura
- dividir componente por responsabilidades
- memoizar solo donde reduzca trabajo real
- virtualizar o paginar listas grandes
- arreglar claves, refs o boundaries SSR

## Checklist de revisión

Usar la checklist completa de:
- `references/checklist.md`

Núcleo mínimo a revisar siempre:
- ¿hay estado que puede derivarse en render?
- ¿hay efectos que en realidad son cálculo?
- ¿las dependencias de hooks son correctas?
- ¿la memoización tiene un motivo medible?
- ¿el componente mezcla demasiadas responsabilidades?
- ¿las listas usan keys estables?
- ¿hay riesgo de hydration mismatch?

## Heurísticas útiles

- Si un valor puede calcularse desde props/estado actual, probablemente no necesita `useState`
- Si un `useEffect` solo copia datos de A a B, probablemente sobra
- Si `useMemo` rodea lógica trivial, probablemente añade ruido
- Si un componente supera claramente una sola responsabilidad, probablemente necesita extracción
- Si el render depende de objetos/funciones recreadas en cada nivel, revisar estabilidad y coste real

## Anti-patrones

- arreglar todo con más `useEffect`
- añadir `useMemo` y `useCallback` “por si acaso”
- duplicar estado remoto/local sin estrategia clara
- culpar a React cuando el problema es estructura de datos o diseño del componente
- recomendar refactors enormes cuando bastaría un cambio pequeño y localizado

## Salida esperada

La respuesta ideal debe devolver:
- síntoma principal
- hallazgos priorizados (`CRITICAL`, `WARNING`, `SUGGESTION`)
- causa raíz probable
- cambio mínimo recomendado
- si hace falta, orden de refactor seguro
