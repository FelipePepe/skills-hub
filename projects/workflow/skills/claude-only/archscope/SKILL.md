---
name: archscope
description: "Trigger: archscope, arquitectura por escenarios, architecture explorer, onboarding docs. Evidence-backed code+data architecture map in docs/archscope/."
license: Apache-2.0
metadata:
  author: "felipepepe"
  version: "1.1"
---

## Activation Contract

Load when asked to map, document or onboard onto a real codebase end-to-end,
especially when the database is part of the story (routines, scheduled jobs,
which flow writes which table). Needs source and/or a reachable database; never
activate on an empty repository. For a code-only map, use `codemap`.

## Hard Rules

1. No static evidence (`file` + `symbol`) → the element does not exist. It goes
   to `unresolved[]` with a reason. Never invent a node, edge, step or claim.
2. Read the reference for a phase in full before running it.
3. The model never parses. Code comes from codebase-memory-mcp (or Read/Grep),
   data from the engine catalog, access classification from `classify_sql.py`.
   Never degrade SQL classification to regex — emit `no-sql-parser` instead.
4. Every step must reference an existing Phase 1 edge, matched on
   `(from, to, call)`. If one step fails, discard the whole flow.
5. Generate artifacts from `assets/` and `scripts/`; never hand-write the HTML
   or the doc tree. `validate_architecture.py` and `generate_docs.py --check`
   must both exit 0 before reporting done.
6. Writes are confined to `docs/archscope/`. Never touch product code, and
   never write to the repository's `docs/` root — that overwrites real docs.
7. In Phase 4 prose, mark every inference in place ("Inferido de las aristas X
   e Y"), and verify risk candidates by reopening **only** the `evidence.file`
   entries the flow already cites.

## Decision Gates

| Condition | Action |
|---|---|
| No CBM index | Offer `index_repository`; else Read/Glob/Grep and note the weaker evidence |
| Relational engine | Use `assets/catalog/{engine}.sql`, then classify bodies with the parser |
| Document / key-value store | Collections only; writes from application code; `engine-exposes-no-logic` |
| No DB credentials | Phase 1B empty, declared `no-db-credentials`. Never guess a schema |
| `sqlglot` missing | Run via `uvx --with sqlglot python …`; if impossible, every access → `no-sql-parser` |
| No job or webhook flow | Report the WARNING as a finding. Never fabricate one for coverage |
| Output dir not empty | `--force` only after confirming it is a prior archscope run |
| Risk candidate unsettled by cited files | Write "no verificable desde la evidencia citada". Never widen the search |

## Execution Steps

1. Read the reference for the phase you are about to run.
2. Phases 1A/1B/1C per the extraction contract. Emit each phase's partial JSON
   before starting the next.
3. Build 6–10 flows per the scenario contract, covering at least one scheduled
   job and one external webhook. Validate; discard failures.
4. Write `docs/archscope/architecture.json`, then
   `validate_architecture.py <path> --fix-stats`.
5. Render `index.html` from the template and confirm it loads.
6. Run `generate_docs.py`, fill every `[[FILL]]` marker per the documentation
   contract, then pass `generate_docs.py --check`.

## Output Contract

Under `docs/archscope/`, always regenerated together: `architecture.json`,
`index.html`, and the doc tree (`README.md`, `01-vision-general.md`,
`escenarios/`, `componentes/`, `datos/modelo.md`, `integraciones.md`,
`huecos.md`, `glosario.md`).

Report: node/edge/flow counts, the resolved-vs-dynamic data-access percentage,
`unresolved[]` grouped by reason, any flow discarded in validation with the
step that broke it, and that zero `[[FILL]]` markers remain.

## References

- `references/extraction-contract.md` — Phases 1A/1B/1C, model, enums.
- `references/scenario-contract.md` — Phase 2 flows, validation, stats.
- `references/viewer-spec.md` — Phase 3 rendering and how to check it.
- `references/documentation-contract.md` — Phase 4 tree, writing rules, risk boundary.
- `assets/` — `architecture.schema.json` (authoritative shape),
  `viewer.template.html`, `catalog/*.sql` per engine.
- `scripts/` — `classify_sql.py`, `validate_architecture.py`, `generate_docs.py`.
