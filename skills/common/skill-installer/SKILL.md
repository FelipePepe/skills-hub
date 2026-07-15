---
name: skill-installer
description: >
  Install Codex skills from curated lists or GitHub repository paths.
  Trigger: When the user asks to list available skills, install a skill, or
  import a skill from another repository.
license: Apache-2.0
metadata:
  author: OpenAI / adapted for skills-hub
  version: "1.0"
---

## When to Use

- The user asks what skills are available
- The user asks to install a curated skill
- The user provides a GitHub repo/path for a skill to install
- The user wants experimental skills from the upstream skills repository

## Core Rules

1. Use the helper scripts; do not reinvent the installer.
2. These flows require network, so request escalation when sandboxing blocks them.
3. After install, remind the user to restart Codex.
4. If the destination skill already exists, stop rather than overwrite silently.
5. System skills are preinstalled; explain that instead of reinstalling them unless the user insists.

## Default Workflow

### List skills

Use the list script when:
- the user asks what is available
- the user names this skill but gives no concrete install target

Examples:

```bash
scripts/list-skills.py
scripts/list-skills.py --format json
scripts/list-skills.py --path skills/.experimental
```

### Install from curated upstream

```bash
scripts/install-skill-from-github.py --repo openai/skills --path skills/.curated/<skill-name>
```

### Install from another repo or URL

```bash
scripts/install-skill-from-github.py --repo <owner>/<repo> --path <path/to/skill>
scripts/install-skill-from-github.py --url https://github.com/<owner>/<repo>/tree/<ref>/<path>
```

## Communication

When listing, present:

1. available skills
2. whether each one is already installed
3. a direct question about which one to install

After installing, say:

> Restart Codex to pick up new skills.

## Notes

- Public repos default to direct download
- Auth failures fall back to sparse checkout
- Private repos can use existing git credentials or `GITHUB_TOKEN` / `GH_TOKEN`
- Multiple `--path` arguments can install several skills in one run

## Output contract

After install emit one line: `INSTALLED:{skill-name} RESTART:required`
After list: emit the skill names one per line, mark `[installed]` where applicable. No prose.
