# Skills Reduction Plan

Working log from the token-reduction discussion (see `docs/skills-token-audit.md`
for the baseline measurements this plan acts on). **Status: closed** — all
agreed items and open threads have been executed or reviewed.

## Agreed items

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

## Open threads — resolved

- Whether the same "worked example → references/" pattern applies to other
  skills beyond `session-start`: **checked, applied where it existed.**
  `session-start` was the only skill with this pattern.
- `session-end`'s own equivalent bulk (2216 tokens, second-heaviest file):
  **reviewed, no action.** Unlike `session-start`, it has no large
  decorative example block — its size comes from load-bearing content
  (classification table, Engram/Atlas heuristics, canonical save format),
  not from something extractable to `references/`.
- `sdd-*` shared-boilerplate review (candidate #3 from the audit):
  **done.** `sdd-init` restated the executor-boundary line and the
  structured-envelope return format inline instead of referencing
  `_shared/sdd-phase-common.md` — fixed to reference Section A/C like
  `sdd-verify` already did. Also removed a stale rule that contradicted
  `sdd-init`'s own compact Step 8 output contract.

## Outcome

Only one skill (`session-start`) had genuine extractable bulk; the rest of
the catalog's size is load-bearing. No further reduction work identified
from this audit.
