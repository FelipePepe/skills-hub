---
name: eu-gdpr
description: >
  Detecta y aplica el Reglamento General de Protección de Datos (GDPR/RGPD) de la UE en proyectos que manejen datos personales de ciudadanos europeos.
  Proactivamente al detectar datos personales, campos de usuario, cookies, tracking, perfiles, o cuando el usuario menciona privacidad, datos personales, consentimientos, o regulaciones de datos.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Cuándo usar

- El proyecto almacena, procesa o transmite datos personales (nombre, email, IP, ubicación, etc.)
- Se implementan formularios de registro/login con datos de usuario
- Hay tracking, analytics, cookies, o perfiles de usuarios
- El usuario menciona privacidad, datos personales, consentimiento, cookies, RGPD, GDPR
- Se manejan datos sensibles (salud, biometría, opiniones políticas, orientación sexual)
- Hay transferencias de datos fuera de la UE/EEE

## Scope guard

- NO usar para proyectos sin datos personales (ej: datos públicos genéricos sin identificación)
- NO usar para proyectos solo de backend sin interacción con usuarios de la UE
- Si no hay datos personales — no hay GDPR aplicable

## Detección

Al iniciar el proyecto, escanear proactivamente:

1. **Schema de base de datos**: campos con `email`, `phone`, `address`, `name`, `ip`, `geo`
2. **Forms/inputs**: registration, login, profile, contact forms
3. **Analytics/cookies**: `analytics.js`, `gtag.js`, `facebook pixel`, `hotjar`, `mixpanel`
4. **APIs externas**: servicios que envían datos fuera de la UE (Stripe, Sentry, New Relic)
5. **Keywords en código**: `consent`, `cookie_policy`, `privacy`, `data_subject`, `right_to_erasure`
6. **Autenticación**: JWT tokens, session cookies, OAuth providers

## Flujo de trabajo

1. **Clasificar** los datos según `references/data-categories.md`
2. **Evaluar** base legal para el procesamiento (Art. 6) desde `references/legal-basis.md`
3. **Aplicar** el checklist correspondiente desde `references/compliance-checklist.md`
4. **Generar** un resumen de compliance al final del desarrollo

## Reglas críticas

- **Datos sensibles**: Nunca almacenar datos de categoría especial sin base legal específica (Art. 9)
- **Consentimiento**: Debe ser libre, específico, informado e inequívoco. No pre-checkeado. No silencioso.
- **Derechos del interesado**: El código DEBE soportar: acceso, rectificación, eliminación, portabilidad, oposición, limitación
- **Privacy by design**: Minimización de datos, retención limitada, cifrado por defecto
- **Transferencias internacionales**: Solo a países con decisión de adecuación o salvaguardas apropiadas
- **DPO**: Obligatorio si el procesamiento es a gran escala de datos sensibles o vigilancia sistemática
- **Violación de datos**: Notificación a autoridad en 72 horas, y al interesado sin demora indebida si hay alto riesgo

## Output

Al revisar datos personales, proporcionar:

```
🇪🇺 EU GDPR Compliance Report
────────────────────────────────
Data Categories: [personal/special/children's]
Legal Basis: [consent/contract/legal_obligation/legitimate_interest]
Processing Locations: [EU-only/international]
Data Subject Rights: [supported rights]
Violations Found: [count]
Recommendations:
  1. [actionable item]
  2. [actionable item]
────────────────────────────────
```

## Recursos

- [`references/data-categories.md`](references/data-categories.md) — Categorías de datos y su nivel de protección
- [`references/legal-basis.md`](references/legal-basis.md) — Bases legales para el procesamiento
- [`references/compliance-checklist.md`](references/compliance-checklist.md) — Checklist accionable por tipo
- [`references/dsar.md`](references/dsar.md) — Guía de Data Subject Rights (derechos del interesado)
