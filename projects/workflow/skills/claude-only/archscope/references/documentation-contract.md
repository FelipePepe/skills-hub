# Documentation contract — Phase 4

Single source: `architecture.json`. Introduce no fact that does not derive from
`nodes`, `edges`, `flows`, `unresolved` or `stats`. Where information is
missing, write that it is missing instead of completing it.

## How the work is split

`scripts/generate_docs.py` writes the whole tree with every structural section
already resolved — counts, traversal tables, reader/writer lists, foreign keys,
gap grouping, and all relative links. Do not hand-write any of it: with dozens
of component pages, cross-links are the first thing that drifts.

The generator leaves `[[FILL:kind]]` markers where judgement is required. Fill
those, and only those. `generate_docs.py --check` exits non-zero while any
marker survives, and it must pass before reporting done.

```bash
python3 scripts/generate_docs.py docs/archscope/architecture.json --out=docs/archscope
# ... fill every [[FILL]] marker ...
python3 scripts/generate_docs.py --check --out=docs/archscope
```

The output root defaults to `docs/archscope/`, never the repository's `docs/`
root: writing `docs/README.md` would overwrite the project's own documentation.
A non-empty destination is refused unless `--force` is passed.

## Tree

```
docs/archscope/
  README.md                  index + reading map
  01-vision-general.md       lanes, count by kind, entrypoints
  escenarios/<flow-id>.md    one per flow
  componentes/<node-id>.md   one per node with lane != external
  datos/modelo.md            tables, FKs, who reads and who writes
  integraciones.md           external systems, callers, scenarios
  huecos.md                  unresolved[] grouped by reason
  glosario.md                domain terms with their location
```

Every file opens with a metadata block: source commit, dirty state, generation
date and extractor version, taken from `meta`. Absent values are written as
**no registrado** — never inferred from the filesystem or the clock.

## Writing rules

- Dense technical prose. No ceremonial introductions, no filler, no "this
  document describes".
- **Always separate extracted fact from inference.** Anything inferred is
  marked in place: "Inferido de las aristas X e Y". A sentence that cannot name
  the edges, files or tables it rests on does not belong in the document.
- Never describe business intent that is not written in the code or its
  comments. If a behaviour looks deliberate but is unjustified, it goes under
  **Preguntas abiertas** at the foot of the document — every generated page has
  that section, and "Ninguna" is a valid answer.
- Language: the generator emits Spanish scaffolding, so write the filled slots
  in Spanish too. Identifiers, paths, table and column names stay verbatim.

## The risk boundary

`Riesgos observables` is the one section that cannot be answered from
`architecture.json`, because transactions, timeouts and retries are properties
of the code. The generator therefore only proposes **candidates** it can derive
from the graph:

| Candidate | Derived from |
|---|---|
| Escrituras múltiples | a flow with ≥2 steps whose edge access is `write` |
| Llamada externa | a step touching a `lane: external` node |
| Escrituras repartidas entre ficheros | write steps citing more than one `evidence.file` |

Confirm or reject each candidate by **re-reading only the `evidence.file`
entries already cited by that flow**. Do not open files the graph does not
cite, and do not search the repository for more risks: that turns a bounded
verification into unbounded speculation. State the concrete line that settles
each candidate, or write that it is not verifiable from the cited evidence.

The same boundary governs "qué ocurre si falla" for external dependencies: only
error handling visible in the cited files counts. If there is none, say so
plainly — an absent `catch` is a finding.

## Filling the markers

| Marker | What it needs |
|---|---|
| `resumen-flujo` | 3–5 lines of business language, derived from the step descriptions |
| `retorno-N` | what step N returns, only if visible in its cited file |
| `fallo-externo` | error handling per external system, from cited files only |
| `riesgos` | verdict per candidate, with the line that settles it |
| `responsabilidad` | inferred from the node's incoming and outgoing edges, marked as inference |
| `proposito-<table>` | inferred from columns and writers, marked as inference |
| `glosario` | one line per domain term, or "no documentado en el código" |
| `preguntas-*` | open questions, or "Ninguna" |

## Report

State: files written, how many scenarios and components, the resolved-access
percentage, and every marker left unfilled (there must be none). If a flow was
discarded in Phase 2, it has no page here — say so, and name it.
