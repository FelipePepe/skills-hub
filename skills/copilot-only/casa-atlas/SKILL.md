---
name: casa-atlas
description: >
  Añade o actualiza documentación en el vault Obsidian (Atlas/Mente) en la NAS sin SSH manual.
  Trigger: cuando hay que documentar algo nuevo en el vault: proyecto, servicio, tecnología.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- Se acaba de implementar algo nuevo que debe quedar documentado
- El usuario dice "documenta esto en atlas" o "añade a mente"
- Se crea un nuevo servicio, proyecto o se aprende algo importante

## Infraestructura

| Dato | Valor |
|------|-------|
| NAS montada en | `/mnt/nas/` en maya (192.168.1.55) |
| Vault path | `/mnt/nas/Obsidian/` |
| App | atlas.casa |

## Comando

```bash
# Desde archivo local (pasar contenido via stdin)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa atlas add <type> "<title>" --content "<markdown>"'

# O pasar contenido largo via heredoc
ssh -o BatchMode=yes felipe@192.168.1.55 'cat > /tmp/nota.md' << 'EOF'
[contenido markdown]
EOF
ssh -o BatchMode=yes felipe@192.168.1.55 'casa atlas add <type> "<title>" --file /tmp/nota.md'
```

## Tipos válidos

| Tipo | Ruta destino |
|------|-------------|
| `proyecto` | `/mnt/nas/Obsidian/Proyectos/<title>.md` |
| `setup` | `/mnt/nas/Obsidian/Setup/<title>.md` |
| `stack` | `/mnt/nas/Obsidian/Stack/<title>.md` |

## Importante: wikilinks bidireccionales

Todo documento debe cumplir:
1. Al menos 2 wikilinks `[[NombreNota]]` a otros documentos del vault
2. Sección `## Ver también` al final
3. Si es `proyecto`: enlazar tecnologías del stack usadas
4. Si es `stack`: incluir `## Proyectos que lo usan`

Ver skill `atlas-docs` para templates completos.

## Alternativa directa (para contenido largo)

Si el contenido es muy largo, escribir directamente via SSH a maya:

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'cat > /mnt/nas/Obsidian/Proyectos/mi-proyecto.md' << 'EOF'
# Mi Proyecto
...contenido...
EOF
```

## Verificar

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'ls /mnt/nas/Obsidian/Proyectos/'
```

## Model routing hints

- preferred agent: documenter
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
