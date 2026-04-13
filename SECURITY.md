# Security Policy

## Supported versions

Este repositorio mantiene una unica linea activa de trabajo en `main`.
Las correcciones de seguridad se aplican sobre la rama principal y se publican en el siguiente release.

## Reporting a vulnerability

Si detectas una vulnerabilidad o riesgo de seguridad:

1. No abras un issue publico con detalles sensibles.
2. Reporta el hallazgo de forma privada al mantenedor del repositorio.
3. Incluye:
   - Descripcion del problema
   - Impacto potencial
   - Pasos para reproducir
   - Propuesta de mitigacion (si aplica)

## Response targets

- Confirmacion inicial: dentro de 72 horas.
- Evaluacion tecnica inicial: dentro de 7 dias.
- Plan de remediacion: segun severidad e impacto.

## Scope reminders for this project

- Verificar especialmente riesgos asociados a `rsync --delete`.
- Validar cambios en scripts que interactuan con rutas absolutas locales.
- Evitar exponer rutas personales o datos sensibles en logs y reportes.
