# OpenCode Adapter

Harness-specific configuration that wires `skills/common/` harnesses into OpenCode.

## Installation

```bash
# 1. Install OpenCode
npm install -g opencode  # or bun/pnpm

# 2. Sync skills and config from skills-hub
skills-hub install --app opencode

# This installs:
# - skills/common/ → ~/.config/opencode/skills/ (symlinked)
# - opencode/opencode.managed.json → merged into ~/.config/opencode/opencode.json
# - opencode/AGENTS.md → ~/.opencode/AGENTS.md (managed block)
```

## What Each Config Provides

### `opencode.managed.json`
Extends `~/.config/opencode/opencode.json` via JSON merge:
- **Agents**: architect, coder, repo-agent, tester, security, documenter, fast
- **Model routing**: maps each agent role to the best available model
- **Slash commands**: `/implement`, `/review-security`, `/test-e2e`, `/docs`, etc.

### `AGENTS.md`
Routing rules injected into `.opencode/AGENTS.md`:
- `@architect` → for architectural decisions, SDD orchestration, proposals, designs
- `@coder` → for implementation, task execution, bug fixes
- `@tester` → for verification, test writing, coverage
- `@security` → for red-team review, adversarial analysis
- `@documenter` → for Atlas docs, ADRs, API docs
- `@fast` → for small mechanical tasks, renaming, formatting

## MCP in OpenCode

OpenCode has native MCP support. To enable the Memory harness via Engram MCP:

```json
// In ~/.config/opencode/opencode.json (or merged via opencode.managed.json)
{
  "mcp": {
    "engram": {
      "type": "stdio",
      "command": "engram-mcp-server",
      "args": ["--db", "~/.engram/memory.db"]
    }
  }
}
```

With Engram available as MCP, OpenCode agents can call `mem_save`, `mem_search`, etc. natively — the same API used in Claude Code. Memory is SHARED between harnesses via the same Engram DB.

## Sub-Agents in OpenCode

OpenCode supports sub-agents via `@agent-name` syntax. Common skills use this pattern:

```
# In a skill prompt, harness-agnostic language:
"Launch an isolated sub-agent to implement the tasks. The sub-agent receives
only the task list, specs, and project standards — no parent context."

# In OpenCode, this maps to:
@coder implement tasks 1.1-1.3 from {tasks.md}
```

The `@agent` invocation creates a fresh session — equivalent to Pi's `createAgent()` or Claude Code's `Agent` tool.

## Skill Discovery in OpenCode

OpenCode reads skills from:
- `.opencode/skills/<name>/SKILL.md`
- `~/.config/opencode/skills/<name>/SKILL.md`
- `.claude/skills/<name>/SKILL.md` (compatible)
- `.agents/skills/<name>/SKILL.md` (compatible)

After `skills-hub install --app opencode`, all `skills/common/` are symlinked to `~/.config/opencode/skills/`. They are immediately available as slash commands.

## Model Routing

Configure per-agent models in `opencode.managed.json`:

```json
{
  "agents": {
    "architect": {
      "model": "anthropic/claude-opus-4-7",
      "description": "Architectural decisions, SDD orchestration, proposals"
    },
    "coder": {
      "model": "ollama/qwen3-coder:30b",
      "description": "Implementation, task execution, bug fixes"
    },
    "tester": {
      "model": "ollama/qwen3-coder:30b",
      "description": "Test writing, verification, coverage"
    },
    "fast": {
      "model": "ollama/gemma3:4b",
      "description": "Small mechanical tasks, low-stakes operations"
    }
  }
}
```

## Directory Structure After Install

```
~/.config/opencode/
├── opencode.json          ← merged with opencode.managed.json
└── skills/
    ├── sdd → {skills-hub}/skills/common/sdd (symlink)
    ├── memory → {skills-hub}/skills/common/memory (symlink)
    ├── review-warlock → {skills-hub}/skills/common/review-warlock (symlink)
    └── ... (all common skills, symlinked)

~/.opencode/
└── AGENTS.md              ← managed block injected
```
