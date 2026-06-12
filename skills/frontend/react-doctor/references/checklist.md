# react-doctor — checklist

## Estado y datos

- ¿Existe estado duplicado que puede derivarse?
- ¿Se almacena en `useState` algo que ya viene de props, cache o selector?
- ¿Hay riesgo de inconsistencias entre dos fuentes de verdad?

## Efectos

- ¿El `useEffect` hace sincronización innecesaria?
- ¿Las dependencias son correctas y estables?
- ¿Hay efectos que disparan renders extra o loops?
- ¿La limpieza (`cleanup`) está bien planteada?

## Render y composición

- ¿El componente tiene demasiadas responsabilidades?
- ¿Se puede extraer lógica a hook o helper puro?
- ¿Hay JSX con demasiada lógica inline?
- ¿Hay props drilling evitable o contexto mal usado?

## Rendimiento

- ¿La memoización reduce trabajo real o solo añade complejidad?
- ¿Hay listas grandes sin virtualización/paginación?
- ¿Las keys de listas son estables?
- ¿Se recalculan estructuras caras en cada render?

## SSR / Hydration

- ¿Hay uso de `window`, `document`, tiempo o aleatoriedad en render?
- ¿Se generan valores distintos entre servidor y cliente?
- ¿Hay markup condicional que diverge entre SSR y cliente?

## Accesibilidad e interacción

- ¿Los controles interactivos tienen semántica correcta?
- ¿Hay focus management roto en modales, menús o overlays?
- ¿Hay eventos que dependen de estructura frágil del DOM?

## Formato recomendado de hallazgos

```markdown
## React Doctor

### CRITICAL
- [file:line] descripción breve

### WARNING
- [file:line] descripción breve

### SUGGESTION
- [file:line] descripción breve

### Root Cause
- explicación corta

### Minimal Fix
- cambio recomendado
```
