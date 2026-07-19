# casa-deploy runbook

> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- The user says "deploy X" or "update X in production" or "deploy X"
- A feature was just merged and needs to be deployed
- A service needs to restart with new configuration

## Infrastructure

| Data | Value |
|------|-------|
| Production machine | maya (192.168.1.55) |
| Runtime | Docker Compose |
| Typical directories | `/home/felipe/<service>` or `/home/felipe/Sources/<service>` |

## Command

```bash
# Auto-detect service directory
ssh -o BatchMode=yes felipe@192.168.1.55 'casa deploy <service>'

# With explicit directory
ssh -o BatchMode=yes felipe@192.168.1.55 'casa deploy <service> --dir /home/felipe/Sources/my-project'
```

## What It Does

1. Locates the directory: first `/home/felipe/<service>`, then `/home/felipe/Sources/<service>`
2. Runs `docker compose pull`
3. Runs `docker compose up -d`
4. Performs a basic post-deploy health check

## Known Services on maya

| Service | Directory |
|---------|-----------|
| `infisical` | `/home/felipe/infisical` |
| `bitwarden-clone` | `/home/felipe/bitwarden-clone` |
| `searxng` | `/home/felipe/searxng` |

## Verify Deploy

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
```

## Notes

- If the service uses Infisical for secrets, secrets are loaded at runtime — nothing extra needed
- If there are DB migrations, run them before the deploy
- Post-deploy logs: `ssh felipe@192.168.1.55 'docker logs <container> --tail 50'`

## Model routing hints

- preferred agent: repo-agent
- preferred model: ollama/devstral:latest
- routing intent: hint only; the skill must not switch models directly
