# casa-domain runbook

> **🏠 CASA LAYER** — Only use this skill when working in a `.casa` intranet project.
> **Detect context by**: presence of `.casa` file in project root, `*.casa` domain references (maya.casa, infisical.casa, pihole.casa), or user explicitly mentions "intranet" or "home project".
> **Work/external projects**: do NOT suggest or use this skill. Skip silently.

## When to Use

- The user says "add domain X.casa" or "create a URL for X"
- The user wants to expose a new service on the intranet with a .casa domain
- The user wants to remove a .casa domain
- The user asks what .casa domains exist

## Infrastructure

| Component | Machine | IP |
|-----------|---------|-----|
| CLI `casa` | maya | 192.168.1.55 |
| nginx | maya | 192.168.1.55 |
| pihole1 DNS | pihole1 | 192.168.1.53 |
| pihole2 DNS | pihole2 | 192.168.1.54 |
| portal.casa | NAS via maya | /mnt/nas/webs/portal.casa/index.html |

## Commands

```bash
# Add domain with nginx reverse proxy and portal card
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'casa domain add <domain> <ip> --port <port> --portal --icon <emoji> --desc "<desc>" --machine <hostname>'

# Add DNS only (no nginx or portal)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain add <domain> <ip>'

# Remove domain
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain remove <domain>'

# List all .casa domains
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain list'
```

## `domain add` Options

| Flag | Description | Example |
|------|-------------|---------|
| `--port <n>` | Service port on maya → creates nginx reverse proxy | `--port 3000` |
| `--portal` | Adds card to portal.casa | |
| `--icon <emoji>` | Card icon (default: 🌐) | `--icon 📊` |
| `--desc <text>` | Description on the portal card | `--desc "My service"` |
| `--machine <name>` | Badge on the card (default: maya/pihole2) | `--machine maya` |

## Real Examples

```bash
# Add Grafana on maya port 3000 with portal
ssh -o BatchMode=yes felipe@192.168.1.55 \
  'casa domain add grafana.casa 192.168.1.55 --port 3000 --portal --icon 📊 --desc "Metrics and dashboards" --machine maya'

# Add DNS only (service on another machine with its own nginx)
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain add new.casa 192.168.1.54'

# Remove
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain remove grafana.casa'
```

## What It Does Internally

1. Creates `/etc/nginx/sites-available/<domain>` on maya + symlink to sites-enabled + nginx reload
2. Adds `address=/<domain>/<ip>` to `/etc/dnsmasq.d/local.conf` on pihole1 AND pihole2 via SSH
3. Restarts pihole-FTL on both piholes
4. If `--portal`: inserts card in Services + updates badge count in portal.casa HTML

## Verify Result

```bash
ssh -o BatchMode=yes felipe@192.168.1.55 'casa domain list'
# The new domain should appear
```

## Manual Fallback

If the `casa` CLI is unavailable or fails, follow the step-by-step manual
procedure (DNS on both Pi-holes, nginx, /etc/hosts on maya, portal card):

- `references/manual-setup.md`

## Model routing hints

- preferred agent: repo-agent
- preferred model: ollama/devstral:latest
- routing intent: hint only; the skill must not switch models directly
