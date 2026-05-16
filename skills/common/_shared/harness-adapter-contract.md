# Harness Adapter Contract

Skills in `skills/common/` are harness-agnostic. They define WHAT to do and WHAT contracts to follow. The harness is responsible for HOW to execute.

This document specifies what each harness must provide so that common skills work without modification.

## Required Harness Capabilities

### 1. Sub-agent Isolation

The harness must be able to launch an isolated sub-agent with:
- A fresh context (no parent conversation)
- A specific prompt
- Access to the same filesystem and memory backend

**Pi**: TypeScript extension registering a tool that calls `createAgent()` or equivalent.
**OpenCode**: `@agent-name` delegation with isolated session.
**Claude Code**: `Agent` tool with `subagent_type`.

Common skills write: "launch an isolated sub-agent with this prompt". The harness executes it.

### 2. Memory Backend

The harness must provide at least one of:

| Backend | API surface expected by skills |
|---|---|
| **Engram** | `mem_save`, `mem_search`, `mem_get_observation`, `mem_context`, `mem_session_summary`, `mem_update` |
| **Filesystem** | Read/write access to `~/.memory/` or `./.memory/` |
| **None** | No persistence — skills operate in ephemeral mode |

Common skills abstract this via persistence mode (`engram | openspec | hybrid | none`). The harness provides the concrete implementation.

### 3. File System Access

The harness must provide:
- `read(path)` — read a file
- `write(path, content)` — write a file
- `bash(command)` — execute a shell command
- `find(pattern)` — search for files
- `grep(pattern, path)` — search within files

### 4. Skill Discovery

The harness must:
- Scan skill directories (`~/.{harness}/skills/`, `./.{harness}/skills/`)
- Load `SKILL.md` frontmatter (name + description) at startup
- Make skills invocable via slash command or natural language trigger
- Load full skill content on demand (not all at startup)

### 5. Model Routing

The harness must respect `model routing hints` in skills:
- `preferred agent: architect | coder | tester | ...`
- `preferred model: {model-id}`
- These are HINTS — the harness may override based on availability or config

### 6. Hooks / Events (optional but enables advanced harnesses)

If the harness supports event hooks, common skills can enable:

| Event | Purpose |
|---|---|
| `session_start` | Trigger memory recovery protocol |
| `session_end` | Trigger session summary save |
| `before_agent_start` | Inject context or system prompt additions |
| `tool_call` | Gate dangerous operations |
| `tool_result` | Transform or audit tool outputs |
| `compaction` | Trigger compaction recovery |

**Pi**: `pi.on('before_agent_start', handler)`
**Claude Code**: hooks in `settings.json`
**OpenCode**: lifecycle events (check OpenCode docs)

Skills that use advanced harness features MUST degrade gracefully when hooks are unavailable — they fall back to manual invocation.

## Adapter Pattern

Harness-specific behavior lives in `skills/adapters/{harness}/`:

```
skills/adapters/
├── pi/
│   ├── README.md         — how to install adapters in Pi
│   ├── memory.ts         — TypeScript extension: Engram memory hooks
│   ├── session-guard.ts  — permission gates for destructive ops
│   └── skill-resolver.ts — auto-inject compact rules before agent starts
│
├── opencode/
│   ├── README.md         — how to configure OpenCode for common skills
│   ├── opencode.managed.json — agents + model routing
│   └── AGENTS.md         — routing rules per task type
│
└── claude/
    ├── README.md         — how to configure Claude Code hooks
    └── hooks.md          — settings.json hook patterns for common skills
```

Adapters are installed separately from skills. A user running Pi installs:
1. `skills/common/` (harness-agnostic skills)
2. `skills/adapters/pi/` (Pi-specific hooks and extensions)

## Versioning

When a common skill uses a capability from this contract, it annotates it:

```yaml
metadata:
  requires:
    - sub-agent-isolation
    - memory-backend
    - file-system-access
```

Skills without `requires` work in any harness with basic file system access.
