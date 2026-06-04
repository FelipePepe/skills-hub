# Checklist de Compliance — EU AI Act

## Sistema Prohibido (Riesgo Inaceptable)

```
❌ NO IMPLEMENTAR
────────────────────────────────
Esta funcionalidad está prohibida por el AI Act (Art. 5).
Explicar al usuario la razón específica de la prohibición.
Proporcionar alternativas legales si es posible.
────────────────────────────────
```

## Sistema de Alto Riesgo

### Documentación técnica
- [ ] Incluir comentarios en el código explicando el propósito del sistema de IA
- [ ] Documentar las limitaciones del modelo
- [ ] Registrar las decisiones de diseño del sistema (arquitectura, datos, métricas)
- [ ] Incluir instrucciones de uso claras en el código (docstrings)

### Datos
- [ ] Validar la calidad y representatividad de los datasets
- [ ] Implementar mitigación de sesgos en el preprocessing
- [ ] Documentar el origen de los datos
- [ ] Incluir mecanismos de anonimización

### Gobernanza
- [ ] Implementar logging de decisiones del modelo
- [ ] Incluir supervisión humana (human-in-the-loop)
- [ ] Validar precisión y robustez del modelo
- [ ] Proteger contra ciberataques (adversarial testing)

### Transparencia
- [ ] Informar a los usuarios sobre la interacción con IA
- [ ] Documentar el impacto en derechos fundamentales
- [ ] Preparar declaración de conformidad UE
- [ ] Planear registro en EU High-Risk AI Database

### Código de ejemplo

```python
# EU AI Act High-Risk System — Compliance Annotations
# Risk Level: HIGH (Annex III — Employment/HR)
# Obligations: documentation, logging, human oversight, bias mitigation

class ResumeScoringSystem:
    """
    EU AI Act Compliance Documentation
    ===================================
    System Purpose: AI-assisted resume screening for recruitment
    Risk Classification: High-risk (Annex III, Art. 6)

    Technical Documentation:
    - Model: [describe architecture]
    - Training Data: [describe source, size, demographics]
    - Bias Mitigation: [describe techniques applied]
    - Intended Limitations: [describe known limitations]

    Compliance Measures:
    - Human review required for all scores < 70 or > 90
    - All decisions logged for audit trail
    - Regular bias audits (quarterly)
    """

    def score_resume(self, resume_data: dict) -> float:
        # Log the decision for audit trail
        decision_log = {
            "timestamp": datetime.utcnow(),
            "input_hash": hash(resume_data),  # never store PII
            "score": self.model.predict(resume_data),
            "requires_human_review": False,
        }

        if decision_log["score"] < 70 or decision_log["score"] > 90:
            decision_log["requires_human_review"] = True

        self._audit_log.append(decision_log)
        return decision_log
```

## Riesgo Limitado (Transparencia)

### Obligaciones mínimas
- [ ] Incluir metadatos de contenido generado por IA
- [ ] Implementar disclosure al usuario final
- [ ] Marcar contenido sintético con metadatos (C2PA/W3C C2PA)

```python
# EU AI Act Transparency Compliance
# Risk Level: LIMITED (Transparency obligations)

from typing import Dict, Any

def generate_content(prompt: str) -> Dict[str, Any]:
    """
    Generates synthetic content using AI.
    EU AI Act Art. 50: Users must be informed of AI interaction.
    """
    result = self.model.generate(prompt)

    # Transparency metadata
    result["metadata"] = {
        "generated_by_ai": True,
        "ai_provider": "self",
        "model_version": "1.0",
        "synthetic_content": True,
        "c2pa_compliant": True,
    }
    return result
```

## Modelo GPAI (Propósito General)

### Obligaciones
- [ ] Documentación técnica del modelo
- [ ] Política de cumplimiento de copyright
- [ ] Resumen público de datos de entrenamiento
- [ ] Mecanismos de información para downstream providers

```python
# GPAI Model Compliance — Training Data Summary
# Obligatory under EU AI Act for general-purpose AI models

TRAINING_DATA_SUMMARY = {
    "description": "Publicly available summary of training data",
    "sources": [
        "Common Crawl (filtered)",
        "Licensed dataset A (licensed)",
        "Open-source corpus B (CC-BY-4.0)",
    ],
    "filtering_method": "Content policy filter + manual review",
    "copyright_compliance": {
        "opt_out_mechanism": "Available via privacy portal",
        "content_removed": True,
        "verification_method": "Automated + manual audit",
    },
}
```

## Buenas Prácticas Voluntarias (Recomendadas para todos los niveles)

- **Privacidad por diseño**: Nunca almacenar datos sensibles sin consentimiento
- **Derecho a explicación**: Siempre proporcionar una razón del resultado
- **Minimización de datos**: Solo procesar datos estrictamente necesarios
- **Accesibilidad**: Asegurar que la IA funcione para personas con discapacidad
- **Auditoría regular**: Implementar revisiones periódicas del sistema
