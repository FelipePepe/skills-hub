# sdd-init — return envelopes by mode

## Engram mode

```markdown
## SDD Initialized

**Project**: {project name}
**Stack**: {detected stack}
**Persistence**: engram
**Strict TDD Mode**: {enabled ✅ / disabled ❌ / unavailable (no test runner)}

### Testing Capabilities
{same table as capabilities template}

### Context Saved
Project context persisted to Engram.
- **Engram ID**: #{observation-id}
- **Topic key**: sdd-init/{project-name}
- **Capabilities ID**: #{capabilities-observation-id}
- **Capabilities key**: sdd/{project-name}/testing-capabilities

No project files created.

### ⚠️ Engram Mode Limitations
- No iteration history
- Not shareable
- Partial audit trail

### Next Steps
Ready for /sdd-explore <topic> or /sdd-new <change-name>.
```

## Openspec mode

```markdown
## SDD Initialized

**Project**: {project name}
**Stack**: {detected stack}
**Persistence**: openspec
**Strict TDD Mode**: {enabled ✅ / disabled ❌ / unavailable (no test runner)}

### Testing Capabilities
{same table as capabilities template}

### Structure Created
- openspec/config.yaml
- openspec/specs/
- openspec/changes/

### Next Steps
Ready for /sdd-explore <topic> or /sdd-new <change-name>.
```

## None mode

```markdown
## SDD Initialized

**Project**: {project name}
**Stack**: {detected stack}
**Persistence**: none (ephemeral)
**Strict TDD Mode**: {enabled ✅ / disabled ❌ / unavailable (no test runner)}

### Testing Capabilities
{same table as capabilities template}

### Context Detected
{summary of detected stack and conventions}

### Recommendation
Enable `engram` or `openspec` for artifact persistence.

### Next Steps
Ready for /sdd-explore <topic> or /sdd-new <change-name>.
```
