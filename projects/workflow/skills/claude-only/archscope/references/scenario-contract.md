# Scenario contract — Phase 2

Identify 6–10 end-to-end business flows. This is the only phase that admits
inference, and it is restricted to edges already extracted in Phase 1.

```
Flow = { id, title, subtitle, entrypoint, trigger, steps[] }
Step = { n, from, to, call, description, branch?, evidence: { file, symbol } }
  trigger ∈ ui | api | job | webhook | queue | cli
```

## Coverage

Cover at least one flow that starts at a **scheduled job** and one that starts
at an **external webhook** — not only interface-initiated ones. These are the
flows nobody documents and the ones that surprise people in production.

If the repository genuinely has no such entrypoint, do not invent one: the
validator emits a WARNING, not an error. Say so in the final report, and check
`unresolved[]` first — an absent webhook flow is sometimes an unparsed router,
which is a gap, not an absence.

## Rules

- Steps are strictly ordered and chained: the `to` of step n is the `from` of
  step n+1, unless the step is an explicitly declared branch (`branch: true`,
  for a fan-out from a shared predecessor such as one handler writing two
  tables).
- Step 1's `from` MUST equal the flow's `entrypoint`.
- **Every step MUST reference an edge that exists in Phase 1**, matched on the
  triple `(from, to, call)`. Validate this and discard the entire flow if any
  step fails. A flow that survives partial repair is not a flow, it is a guess.
- `description`: 1–2 sentences on what it does and what it writes or returns,
  citing real files and tables.
- Steps touching `lane: data` name the concrete table and whether it is a read
  or a write. The `access` comes from the referenced edge, so a step cannot
  claim a write the graph does not have.
- `call` is the real endpoint, function or routine — never prose.

## Ordering

Order `flows[]` by onboarding value, not by discovery order: the canonical happy
path first, then the money/state-changing paths, then the scheduled and
webhook-driven ones, then the edge cases. The viewer preserves array order, and
a reader works down the list top to bottom.

## Stats

`stats` is computed by `scripts/validate_architecture.py --fix-stats`; do not
hand-write it.

```
nodes_by_lane   : count per lane
edges_by_access : count per access
data_access     : { resolved, dynamic, pct_resolved }
```

`resolved` counts edges with `access: read|write` landing on a `lane: data`
node. `dynamic` counts `unresolved[]` entries whose reason is `dynamic-sql`,
`sql-parse-error` or `no-sql-parser`. `pct_resolved = resolved / (resolved +
dynamic)`. A low percentage is a legitimate result: it says the data access is
mostly built at runtime, which is itself the finding.

## Output

Emit `architecture.json = { nodes, edges, flows, unresolved, stats, meta? }`.
From that point on, introduce no datum that is not in that file — the viewer is
a projection of it, never a second source.
