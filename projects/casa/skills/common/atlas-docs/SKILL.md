---
name: atlas-docs
description: "Create or update documents in the Atlas (Obsidian) vault with bidirectional wikilinks. Trigger: document something in atlas.casa, the vault, or new intranet work."
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- The user says "update the atlas.casa docs" or "document this in Atlas"
- Something new was just implemented on the intranet (new service, domain, feature)
- The user asks to create a new note in the vault
- A note is detected without links to other related notes
- The user asks about documentation state

## Vault Infrastructure

| Data | Value |
|------|-------|
| **Machine** | pihole2 — `192.168.1.54` |
| **Vault path** | `/home/sandman/Obsidian/` |
| **SSH user** | `felipe` (uses `sudo tee` to write as `sandman`) |
| **App** | `atlas.casa` (React + obsidian-api backend) |

### Folder Structure

```
/home/sandman/Obsidian/
├── Stack/
│   ├── _INDEX.md          ← Master index of the entire vault
│   ├── AI-ML/             ← LangChain, Ollama, CrewAI, RAG, Whisper, Vosk...
│   ├── Auth/              ← JWT, BcryptJS, TOTP-2FA
│   ├── Backend/           ← Express, FastAPI, SpringBoot, Hono, Kafka
│   ├── Databases/         ← PostgreSQL, SQLite, MySQL, ChromaDB
│   ├── DevOps/            ← Docker, GitHubActions, Prometheus, Grafana...
│   ├── Frontend/          ← React, Angular, NextJS, Vite, TailwindCSS...
│   ├── Languages/         ← TypeScript, Python, Go, Java, Rust, Kotlin...
│   ├── ORM/               ← DrizzleORM, SpringDataJPA
│   ├── Testing/           ← Vitest, Playwright, Pytest, JUnit
│   └── Tools/             ← ESLint, Prettier, Zod, Swagger, Drizzle-Kit
├── Projects/              ← Notes for concrete projects
└── Setup/                 ← Infrastructure, devices, services
    ├── _INDEX.md (or network in Red-Local-Servicios.md)
    ├── Dispositivos.md
    ├── Red-Local-Servicios.md
    ├── Agent-Skills.md
    ├── Syncthing-RPi.md
    ├── Dropbox-Sync.md
    └── KDE-Connect.md
```

## Wikilink Rules — CRITICAL

Obsidian resolves wikilinks by **filename** (no path, no `.md`).

```markdown
[[NoteName]]                          ← simple link
[[NoteName|Visible text]]             ← link with alias
[[ExplicitFolder/NoteName|Alias]]     ← link with path (for disambiguation)
```

### Mandatory Rules

1. **Every document must have at least 2 wikilinks** to other vault documents
2. **Links must be bidirectional**: if A links to B, B must link to A
3. **"## See Also" section** at the end of EVERY note — always
4. **Stack notes**: include "## Related Stack" with sibling technologies
5. **Projects**: link to the Stack technologies they use
6. **Setup**: cross-link each other (Dispositivos ↔ Red-Local-Servicios ↔ relevant Projects)
7. **`Stack/_INDEX.md`**: update when a new note is added

### Exact Filenames (for correct wikilinks)

Filenames without extension are the identifiers:

**Stack/Frontend:** React, Angular, AngularMaterial, NextJS, Vite, TailwindCSS, RadixUI, ShadcnUI, TanStackQuery, FramerMotion, Recharts  
**Stack/Backend:** ExpressJS, FastAPI, SpringBoot, Hono, Kafka  
**Stack/Languages:** TypeScript, Python, Go, Java, JavaScript, CSharp, Rust, Kotlin  
**Stack/AI-ML:** LangChain, LangGraph, LangSmith, CrewAI, Ollama, PyTorch, MCP, RAG, Whisper, Vosk  
**Stack/Databases:** PostgreSQL, SQLite, MySQL, ChromaDB  
**Stack/ORM:** DrizzleORM, SpringDataJPA  
**Stack/Testing:** Vitest, Playwright, Pytest, JUnit  
**Stack/Auth:** JWT, BcryptJS, TOTP-2FA  
**Stack/DevOps:** Docker, GitHubActions, Prometheus, Grafana, Vercel, SonarQube  
**Stack/Tools:** ESLint, Prettier, Zod, Swagger, Drizzle-Kit  
**Setup:** Dispositivos, Red-Local-Servicios, Agent-Skills, Syncthing-RPi, Dropbox-Sync, KDE-Connect  
**Projects:** obsidian-clone (Mente), netscan, dotnet-cache-poc, dotnet-framework-cache-evolution

## Work Protocol

### Step 1 — Discover Current State
```bash
ssh felipe@192.168.1.54 "find /home/sandman/Obsidian -name '*.md' | sort"
ssh felipe@192.168.1.54 "grep -r '\[\[' /home/sandman/Obsidian/Setup/ --include='*.md' -l"
```

### Step 2 — Audit Missing Links
For each note to create/update, identify:
- Which other vault notes mention it or should mention it?
- Does it have a "## See Also" section?
- Is it in `_INDEX.md`?

### Step 3 — Write/Update Notes
```bash
# Always with sudo tee (files belong to sandman, we connect as felipe)
ssh felipe@192.168.1.54 'sudo tee /home/sandman/Obsidian/FOLDER/Note.md > /dev/null << '"'"'EOF'"'"'
[markdown content with wikilinks]
EOF
echo "OK"'
```

### Step 4 — Update Notes That Should Link to the New One
If you create `Projects/new-tool.md` that uses React and TypeScript:
- Update `Stack/Frontend/React.md` → add to "## Projects Using It"
- Update `Stack/Languages/TypeScript.md` → same
- Update `Stack/_INDEX.md` → add in the Projects section

### Step 5 — Verify in atlas.casa
```bash
curl -s http://atlas.casa/api/notes | python3 -c "import json,sys; notes=json.load(sys.stdin); print(f'{len(notes)} notes in vault')"
```

## Templates

### Template: Stack Note

```markdown
# {Name}

> {One-line description}. Used with [[{Related1}]] and [[{Related2}]].

## What Is It?
{2-3 line description. Include at least 2 wikilinks to related technologies.}

## Related Stack
[[Tech1]] · [[Tech2]] · [[Tech3]]

## Installation
```bash
{install command}
```

## Basic Usage
```{lang}
{minimal working example}
```

## Projects Using It
- [[Projects/project-name|Project Name]] — {how it is used}

## See Also
- [[RelatedTechnology1]] — {relationship}
- [[RelatedTechnology2]] — {relationship}
- [[Red-Local-Servicios]] — {only if it applies to the intranet}
```

### Template: Project Note

```markdown
# {Project Name}

**Last updated:** {YYYY-MM-DD}

## Description
{What the project does. Link the stack technologies used.}

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend | [[React]], [[Vite]], [[TypeScript]] |
| Backend | [[ExpressJS\|Express]], [[TypeScript]] |
| ...

## Architecture
```
{ASCII diagram or description}
```

## Project State
- [x] Feature 1
- [ ] Feature 2 (pending)

## Deploy
```bash
{deploy commands}
```

## See Also
- [[Red-Local-Servicios]] — nginx configuration
- [[Dispositivos]] — machines involved
- [[Related Stack]] — technologies used
```

### Template: Setup Note

```markdown
# {Service/Config}

**Last updated:** {YYYY-MM-DD}

## Description
{What it is and what it does on the intranet.}

## Infrastructure

| Data | Value |
|------|-------|
| Machine | [[Dispositivos\|pihole2]] (192.168.1.54) |
| Domain | `service.casa` |
| ...

## Configuration
{details}

## Useful Commands
```bash
{commands}
```

## See Also
- [[Dispositivos]] — network inventory
- [[Red-Local-Servicios]] — nginx configuration
- [[Projects/related-project]] — {if applicable}
```

## Date and Format Conventions

- Date: `**Last updated:** YYYY-MM-DD`
- H1 heading required in every note
- Tables for structured data (inventories, endpoints, commands)
- Code blocks with language specified (` ```bash `, ` ```tsx `, etc.)
- Emojis optional in section headings (only in `_INDEX.md`)

## Current .casa Domains (for references in notes)

| Domain | Service | Machine |
|--------|---------|---------|
| `atlas.casa` | Notes app (Atlas) | pihole2 |
| `obsidian.casa` | Legacy Atlas alias | pihole2 |
| `portal.casa` | Intranet dashboard | pihole2 |
| `ha.casa` | Home Assistant | pihole2 |
| `nas.casa` | FileBrowser NAS | maya |
| `maya.casa` | maya machine | maya |
| `pihole2.casa` | Pi-hole 2 panel | pihole2 |
| `pihole1.casa` | Pi-hole 1 panel | pihole1 |
| `clockwork.casa` | clockworkpi | clockwork |
| `router.casa` | Router | 192.168.1.1 |

## Model routing hints

- preferred agent: documenter
- preferred model: ollama/qwen3.6:27b
- routing intent: hint only; the skill must not switch models directly
