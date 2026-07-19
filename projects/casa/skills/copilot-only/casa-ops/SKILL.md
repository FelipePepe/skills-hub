---
name: casa-ops
description: "Operations runbooks for the .casa intranet: domains (DNS/nginx/portal), docker service deploys, static web deploys, Infisical secrets rules, Trello CLI, full project workflow. Trigger: deploy, 'add/remove X.casa domain', 'publish on the intranet', secrets or .env in .casa projects, 'trello board/card', or how we work on intranet projects."
license: Apache-2.0
metadata:
  author: Felipe Perez
  version: "1.0"
---
> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## How to Use

This is a router. Identify the operation, then load ONLY the matching runbook
from `references/` before acting:

| Operation | Runbook |
| --------- | ------- |
| Add/remove/list a `.casa` domain (DNS, nginx, portal card) | `references/domains.md` |
| Manual domain setup when the `casa` CLI is unavailable | `references/manual-domain-setup.md` |
| Deploy/update a dockerized service on maya (compose pull + up) | `references/docker-deploy.md` |
| Deploy a web app (build, copy to NAS, nginx, DNS, portal) | `references/web-deploy.md` |
| Secrets, env vars, `.env`, Infisical rules for `.casa` projects | `references/secrets.md` |
| Trello clone CLI (boards, lists, cards) + SDD/Atlas integration | `references/trello.md` (details in `references/trello/`) |
| Full project workflow, zero to production ("how do we work") | `references/project-workflow.md` |

## Rules

- Load one runbook at a time; do not preload all references.
- Never put real secrets in `.env` — all secrets live in Infisical (see `references/secrets.md`).
- Related skills that stay separate: `poc-init` (new PoC scaffolding), `atlas-docs` (vault documentation).
