# Progressive Disclosure

Keep the main skill small and load extra detail only when needed.

## Three levels

1. **Frontmatter**  
   Always visible. Make it trigger well.

2. **SKILL.md body**  
   Loaded when the skill triggers. Keep it lean and operational.

3. **Bundled resources**  
   Read only on demand: references, scripts, assets.

## Good pattern

- `SKILL.md`: workflow + decisions
- `references/aws.md`: provider-specific details
- `references/gcp.md`: another variant

## Bad pattern

- putting every variant, framework, and edge case into one huge `SKILL.md`

## Rule of thumb

If a section is:
- optional
- verbose
- framework-specific
- domain-specific

it probably belongs in `references/`.
