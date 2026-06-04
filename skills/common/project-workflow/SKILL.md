---
name: project-workflow
description: >
  Flujo de trabajo completo para crear y desplegar proyectos en la intranet.
  Desde cero hasta producción: SDD + GitFlow + Infisical + Deploy + DNS + Atlas.
  Trigger: cuando el usuario quiere empezar un proyecto nuevo o cuando pregunta
  cómo trabajamos.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---

## Flujo Completo

```
FASE 1 — ARRANQUE
  casa project init <nombre> [--secrets] [--github] [--template node|angular]

FASE 2 — DISEÑO
  /sdd-new <nombre>   →  proposal → spec → design → tasks

FASE 3 — DESARROLLO
  GitFlow (`feature/*`, `release/*`, `hotfix/*`) + conventional commits
  /sdd-apply          →  implementar tasks
  casa atlas add      →  documentar decisiones DURANTE el desarrollo

FASE 4 — VERIFICACIÓN
  /sdd-verify         →  validar contra spec
  tests locales
  smoke test en staging local (docker compose up en dev)

FASE 5 — RELEASE
  PR develop → main + code review (aunque sea self-review)
  git tag semántico (v1.0.0) + CHANGELOG

FASE 6 — PRODUCCIÓN
  casa deploy <nombre>
  health check: curl http://localhost:<port>/health
  casa domain add <nombre>.casa <ip> --port <n> --portal --icon <emoji> --desc "<desc>"

FASE 7 — CIERRE
  casa atlas add proyecto "<nombre>" --file nota.md   (actualizar con URL prod)
  engram mem_save (arquitectura, decisiones, gotchas)
  /sdd-archive <nombre>
```

## Fase 1 — `casa project init` en detalle

```bash
# Mínimo (solo git + directorio deploy)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa project init <nombre>'

# Con vault Infisical (si el proyecto usa secretos)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa project init <nombre> --secrets --envs dev,prod'

# Con repo GitHub privado
ssh -o BatchMode=yes felipe@192.168.1.55 'casa project init <nombre> --secrets --github'
```

Esto crea:
- `/home/felipe/<nombre>/` — directorio de deploy en maya
- Repo git con branches `main` y `develop`
- (opt) Repo privado en GitHub
- (opt) Proyecto en Infisical con environments y Machine Identity

## Fase 2 — SDD

```
/sdd-new <nombre>        ← arranca el ciclo completo
/sdd-continue <nombre>   ← continúa la siguiente fase
/sdd-apply <nombre>      ← implementa los tasks
/sdd-verify <nombre>     ← valida contra spec
/sdd-archive <nombre>    ← cierra el cambio
```

## Fase 3 — GitFlow

```bash
# Feature
git checkout develop
git pull
git checkout -b feature/<nombre>

# Commits convencionales
git commit -m "feat: add login endpoint"
git commit -m "fix: handle expired JWT"
git commit -m "chore: update dependencies"

# PR feature → develop
gh pr create --base develop --title "feat: <descripción>"

# Release
git checkout develop
git pull
git checkout -b release/v1.0.0
gh pr create --base main --title "release: v1.0.0"

# Tras merge a main
git tag v1.0.0
git checkout develop && git merge --no-ff main
```

## Fase 3 — Infisical (si `--secrets`)

```bash
# Output de casa project init --secrets:
# Client ID:     abc123
# Client Secret: xyz789   ← solo en bootstrap .env

# .env mínimo del proyecto (SOLO credenciales Infisical)
INFISICAL_CLIENT_ID=abc123
INFISICAL_CLIENT_SECRET=xyz789
INFISICAL_SITE_URL=http://infisical.casa

# Todos los demás secretos van DIRECTAMENTE en infisical.casa
# No hay más variables en .env
```

Ver skill `infisical-vault` para el patrón de código.

## Fase 5 — Release checklist

- [ ] Todos los tests pasan
- [ ] /sdd-verify verde
- [ ] PR aprobado (aunque sea self-review)
- [ ] CHANGELOG actualizado
- [ ] Tag semántico creado
- [ ] `develop` actualizado con los cambios del release

## Fase 6 — Deploy

```bash
# Deploy
ssh -o BatchMode=yes felipe@192.168.1.55 'casa deploy <nombre>'

# Health check post-deploy
ssh -o BatchMode=yes felipe@192.168.1.55 'curl -sf http://localhost:<port>/health || echo FAIL'

# Añadir dominio + portal (solo cuando el health check pasa)
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'casa domain add <nombre>.casa 192.168.1.55 --port <port> --portal \
   --icon <emoji> --desc "<descripción>" --machine maya'

# Verificar DNS desde la red
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain list | grep <nombre>'
```

## Rollback

```bash
# Si el deploy falla:
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'cd /home/felipe/<nombre> && git checkout <tag-anterior> && docker compose up -d'
```

## Fase 7 — Documentación cierre

### Atlas (actualizar nota con URL prod)
```bash
ssh -o BatchMode=yes felipe@192.168.1.55 \
  "sed -i 's|## Deploy|## URL Producción\n\`http://<nombre>.casa\`\n\n## Deploy|' \
  /mnt/nas/Obsidian/Proyectos/<nombre>.md"
```

### Engram
```
mem_save title: "Deployed <nombre> to production"
type: architecture
content: What/Why/Where/Learned
```

## Reglas de oro

1. **Vault ANTES que código** — nunca `.env` con datos reales en el repo
2. **SDD ANTES de implementar** — spec y diseño primero, código después
3. **Documentar DURANTE el desarrollo** — no al final
4. **Health check ANTES del dominio** — no añadir al portal si el servicio falla
5. **Conventional commits siempre** — feat/fix/chore/docs/refactor/test

## Herramientas de referencia

| Herramienta | Skill |
|-------------|-------|
| Proyecto completo | `project-workflow` (este) |
| Dominios .casa | `casa-domain` |
| Vault Infisical | `casa-vault` + `infisical-vault` |
| Deploy producción | `casa-deploy` |
| Documentación Atlas | `casa-atlas` + `atlas-docs` |
| SDD completo | skills `sdd-*` |
| GitFlow | skill `gitflow` |

## Model routing hints

- preferred agent: architect
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
