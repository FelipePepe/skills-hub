# Claude Code Adapter

Harness-specific configuration that wires `skills/common/` harnesses into Claude Code (the CLI).

## Installation

```bash
# 1. Sync skills from skills-hub (already done if you use skills-hub)
skills-hub install --app claude

# This symlinks skills/common/ → ~/.claude/skills/
# Claude Code discovers them automatically at startup.
```

## What Each Config Provides

### Hooks (`settings.json`)

Claude Code hooks are shell commands that execute in response to events. They wire common harnesses without modifying Claude's core behavior.

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started' && engram mem-context 2>/dev/null || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "engram session-summary 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### Memory Harness in Claude Code

Claude Code uses Engram natively via MCP tools (`mem_save`, `mem_search`, etc.). The Memory harness skill (`skills/common/memory/SKILL.md`) provides the protocol — Claude Code provides the tools.

No additional configuration needed if Engram MCP is already configured in `~/.claude/settings.json`.

### Sub-Agents in Claude Code

Claude Code uses the `Agent` tool for sub-agent isolation. Common skills use harness-agnostic language ("launch isolated sub-agent"), which maps to:

```python
# Claude Code internally
Agent(
  description="SDD apply — implement tasks 1.1-1.3",
  prompt="...",
  subagent_type="general-purpose"
)
```

The `Agent` tool provides:
- Fresh context (no parent conversation)
- Isolated token budget
- Access to same filesystem and Engram DB

### Model Routing in Claude Code

Set per-task model preferences via CLAUDE.md or project settings. Common skills include routing hints:
```yaml
model routing hints:
  preferred agent: architect
  preferred model: claude-opus-4-7
```

Claude Code respects these as suggestions when the `Agent` tool is called with a model override.

## Skill Registry Auto-Refresh

Add to your project's CLAUDE.md or hook:

```bash
# Run after adding/modifying skills
# Refreshes the skill registry used by the SDD orchestrator
/skill-registry
```

Or automate via hook:
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "cd {project} && node .atl/refresh-registry.js 2>/dev/null || true"
      }]
    }]
  }
}
```

## Directory Structure After Install

```
~/.claude/
├── settings.json          ← add hooks for Memory harness
├── CLAUDE.md              ← global instructions (Engram protocol, personality)
└── skills/
    ├── sdd → {skills-hub}/skills/common/sdd (symlink)
    ├── memory → {skills-hub}/skills/common/memory (symlink)
    ├── review-warlock → {skills-hub}/skills/common/review-warlock (symlink)
    ├── delivery-strategy → {skills-hub}/skills/common/delivery-strategy (symlink)
    └── ... (all common skills, symlinked)
```

## Compatibility Note

Claude Code also reads `skills/copilot-only/` skills (synced to `~/.claude/skills/` via the legacy `claude-only` channel — currently empty). Common skills take priority. Copilot-only skills remain available but are being migrated to `common/`.
