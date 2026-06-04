---
name: eu-ai-act
description: >
  Detecta y aplica el Reglamento de IA de la Unión Europea (AI Act) en proyectos con sistemas de inteligencia artificial.
  Proactivamente al iniciar un proyecto con dependencias de IA, detectar imports de librerías de ML, o cuando el usuario menciona IA, modelos, datos, compliance o regulación.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Cuándo usar

- El proyecto tiene dependencias de IA/ML (OpenAI, Anthropic, LangChain, TensorFlow, PyTorch, etc.)
- El código usa APIs de modelos de lenguaje o generación de contenido
- El usuario menciona IA, compliance regulatorio, datos de entrenamiento, o regulaciones
- Se detectan imports de librerías de ML/AI en el código fuente
- Se trabaja con biometría, reconocimiento facial, inferencia de emociones, o scoring

## Scope guard

- NO usar para proyectos sin componentes de IA/ML
- NO usar para generalidades sobre programación sin IA
- Si no hay sistema de IA, NO hay obligaciones del AI Act que aplicar

## Detección

Al iniciar el proyecto, escanear proactivamente:

1. **Dependencias**: `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`
   - Keywords: `openai`, `anthropic`, `langchain`, `tensorflow`, `pytorch`, `transformers`, `replicate`, `ollama`, `groq`, `cohere`, `mistral`
2. **Imports en código**: buscar patrones de import de librerías de IA
3. **Uso de APIs externas**: llamadas a endpoints de modelos de IA
4. **Datos sensibles**: procesamiento de datos biométricos, de salud, financieros, o de menores

## Flujo de trabajo

1. **Clasificar** el riesgo del sistema de IA usando `references/risk-matrix.md`
2. **Evaluar** obligaciones según el nivel de riesgo (prohibido / alto riesgo / transparencia / ninguno)
3. **Aplicar** el checklist correspondiente desde `references/compliance-checklist.md`
4. **Verificar** deadlines aplicables en `references/deadlines.md`
5. **Generar** un resumen de compliance al final del desarrollo

## Reglas críticas

- **Sistemas prohibidos**: Nunca ayudar a implementar funcionalidades de riesgo inaceptable
- **Alto riesgo**: Si el sistema califica como high-risk, el código DEBE incluir:
  - Documentación técnica integrada (comentarios explicando el sistema de IA)
  - Logging de decisiones del modelo
  - Mecanismos de supervisión humana
  - Validación de calidad de datos de entrada
- **Transparencia**: El código DEBE incluir marcas de metadatos para contenido generado por IA (Watermarking, etiquetas)
- **Datos personales**: Priorizar minimización de datos y anonimización
- **GPAI models**: Si se usa un modelo de propósito general, aplicar obligaciones de transparencia de entrenamiento

## Output

Al revisar código con IA, proporcionar:

```
🇪🇺 EU AI Act Compliance Report
────────────────────────────────────
Risk Level: [unacceptable / high / limited / minimal]
Applicable Obligations: [list]
Deadline: [date or N/A]
Violations Found: [count]
Recommendations:
  1. [actionable item]
  2. [actionable item]
────────────────────────────────────
```

## Recursos

- [`references/risk-matrix.md`](references/risk-matrix.md) — Clasificación de riesgo detallada
- [`references/compliance-checklist.md`](references/compliance-checklist.md) — Checklist accionable por nivel
- [`references/deadlines.md`](references/deadlines.md) — Cronología regulatoria
