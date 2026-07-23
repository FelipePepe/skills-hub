# Skills Reduction Plan

Working log from the token-reduction discussion (see `docs/skills-token-audit.md`
for the baseline measurements this plan acts on). Nothing here is executed
until the discussion is closed and each item is confirmed — this is a plan
document, not a changelog.

## Agreed items (pending execution)

1. **`session-start` (claude-only) — extract "Example Output" block**
   - Location: `projects/workflow/skills/claude-only/session-start/SKILL.md`,
     lines ~214-248 ("## Example Output (vi-sdd, simulated)").
   - Move the fully worked vi-sdd example (~35 lines, ~600-700 tokens) to
     `references/example-output.md`; leave a one-line pointer in SKILL.md.
   - Rationale: the block only demonstrates format — the format itself is
     already fully specified by the two templates in Step 8 (resumption +
     onboarding). It's not load-bearing for behavior, only for a human/model
     skimming for an example.
   - Status: **executed** — moved to `references/example-output.md`, SKILL.md now has a one-line pointer (v1.7).

## Open threads

- Whether the same "worked example → references/" pattern applies to other
  skills beyond `session-start` (not yet checked).
- `session-end`'s own equivalent bulk (2216 tokens, second-heaviest file) not
  yet reviewed for the same kind of extractable block.
- `sdd-*` shared-boilerplate review (candidate #3 from the audit) not yet
  started.

## Execution order

To be filled in once the discussion closes.
