# Pi Adapter

Harness-specific extensions that wire `skills/common/` harnesses into Pi's event system.

## Installation

```bash
# 1. Install Pi
npm install -g @earendil-works/pi  # or bun/pnpm

# 2. Sync skills from skills-hub
skills-hub install --app pi

# 3. Install Pi extensions (adapters)
pi install path:./skills/adapters/pi
# or copy to ~/.pi/agent/extensions/
```

## What Each Extension Does

### `memory.ts`
Wires the Memory harness (#10) to Pi's event system:
- `before_agent_start` → calls `mem_context` and injects last session summary into system prompt
- `settled` (session end) → triggers `mem_session_summary`
- `session_before_compact` → saves compaction summary to Engram before Pi compacts

Requires: Engram MCP server running and accessible.

### `skill-resolver.ts`
Wires Skill Digestion harness (#15) into Pi:
- `before_agent_start` → reads skill registry from Engram or `.atl/skill-registry.md`
- Injects `## Project Standards (auto-resolved)` into system prompt with compact rules matching current task context

### `session-guard.ts`
Wires Permission/Security harness (#23) into Pi:
- `tool_call` → intercepts destructive operations (`rm -rf`, `git reset --hard`, `DROP TABLE`, etc.)
- Asks for user confirmation before executing
- Logs all destructive operations to session

## Extension File Template

```typescript
// skills/adapters/pi/memory.ts
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

export default async function (pi: ExtensionAPI) {
  // Hook: inject memory context at session start
  pi.on('before_agent_start', async (ctx) => {
    // Call mem_context via bash (Engram CLI or MCP tool)
    // Inject result into system prompt additions
    return { systemPromptAdditions: '...' };
  });

  // Hook: save session summary at end
  pi.on('settled', async () => {
    // Trigger mem_session_summary
  });
}
```

## Engram Setup for Pi

Pi does not include Engram natively. To use the Memory harness in Pi:

**Option A — Engram CLI** (if Engram has a CLI):
```bash
# Extensions call Engram via bash tool
pi.exec('engram', ['mem_context', '--project', projectName])
```

**Option B — Engram MCP Server**:
```bash
# Run Engram as MCP server, connect via Pi extension
pi install npm:@your-org/pi-engram  # if a Pi-Engram adapter package exists
```

**Option C — Filesystem fallback**:
```bash
# Extensions read/write ~/.memory/*.md directly
# Simpler but no search capabilities
```

## Model Routing in Pi

Pi supports model routing via extensions:

```typescript
pi.on('before_agent_start', async (ctx) => {
  const phase = detectCurrentSddPhase();
  const model = MODEL_ROUTING[phase];
  if (model) await pi.setModel(model);
});

const MODEL_ROUTING = {
  orchestrator: 'anthropic/claude-opus-4',
  apply:        'anthropic/claude-sonnet-4',
  verify:       'anthropic/claude-opus-4',
  archive:      'anthropic/claude-haiku-4',
};
```

## Directory Structure After Install

```
~/.pi/agent/
├── skills/
│   ├── sdd/               ← from skills/common
│   ├── sdd-init/
│   ├── memory/
│   ├── review-warlock/
│   ├── delivery-strategy/
│   └── ... (all common skills)
└── extensions/
    ├── memory.ts           ← from skills/adapters/pi
    ├── skill-resolver.ts
    └── session-guard.ts
```
