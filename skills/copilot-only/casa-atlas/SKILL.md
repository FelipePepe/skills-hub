---
name: casa-atlas
description: >
  Adds or updates documentation in the Obsidian vault (Atlas/Mente) on the NAS without
  manual SSH. Trigger: when something new needs to be documented in the vault: project,
  service, technology.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- Something new was just implemented that needs to be documented
- The user says "document this in atlas" or "add to Atlas"
- A new service or project is created, or something important is learned

## Infrastructure

| Data | Value |
|------|-------|
| NAS mounted at | `/mnt/nas/` on maya (192.168.1.55) |
| Vault path | `/mnt/nas/Obsidian/` |
| App | atlas.casa |

## Command

```bash
# From a local file (pass content via stdin)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa atlas add <type> "<title>" --content "<markdown>"'

# Or pass long content via heredoc
ssh -o BatchMode=yes felipe@192.168.1.55 'cat > /tmp/note.md' << 'EOF'
[markdown content]
EOF
ssh -o BatchMode=yes felipe@192.168.1.55 'casa atlas add <type> "<title>" --file /tmp/note.md'
```

## Valid Types

| Type | Destination path |
|------|----------------|
| `project` | `/mnt/nas/Obsidian/Projects/<title>.md` |
| `setup` | `/mnt/nas/Obsidian/Setup/<title>.md` |
| `stack` | `/mnt/nas/Obsidian/Stack/<title>.md` |

## Important: Bidirectional Wikilinks

Every document must meet:
1. At least 2 wikilinks `[[NoteName]]` to other vault documents
2. `## See Also` section at the end
3. If `project`: link to the stack technologies used
4. If `stack`: include `## Projects Using It`

See skill `atlas-docs` for complete templates.

## Direct Alternative (for long content)

If the content is very long, write directly via SSH to maya:

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'cat > /mnt/nas/Obsidian/Projects/my-project.md' << 'EOF'
# My Project
...content...
EOF
```

## Verify

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'ls /mnt/nas/Obsidian/Projects/'
```

## Model routing hints

- preferred agent: documenter
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
