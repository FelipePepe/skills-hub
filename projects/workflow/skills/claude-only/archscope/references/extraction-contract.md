# Extraction contract — Phases 1A, 1B, 1C

The graph is deterministic. Only Phase 2 grouping admits inference, and only
over edges already extracted here. No static evidence (file + symbol) → the
element does not exist: it goes to `unresolved[]` with a reason. A graph with
declared holes is worth more than a complete one with invented filler.

## Model

```
Node = { id, label, subtitle, lane, kind, files[] }
  lane ∈ client | frontend | backend | infra | data | external
  kind ∈ app | service | function | worker | ci | queue | storage
         | table | view | package | procedure | job | external-api

Edge = { id, from, to, call, access, evidence: { file, symbol, line? } }
  call   = the real function name, endpoint or routine — never a description
  access ∈ read | write | call | http | publish | consume
```

`assets/architecture.schema.json` is the authoritative shape. Both enums are
closed: a concept that does not fit is a modelling error, not a new value.

`unresolved[] = { file, symbol?, reason, detail? }`. Valid reasons are listed in
the schema (`dynamic-sql`, `dynamic-import`, `dynamic-dispatch`,
`sql-parse-error`, `no-sql-parser`, `no-db-credentials`,
`engine-exposes-no-logic`, `external-binary`, `generated-code`,
`unindexed-language`).

## Phase 1A — code graph

Extract from AST and imports, never from names or conventions. Prefer
codebase-memory-mcp when an index exists (`search_graph`, `trace_path`,
`get_code_snippet` for the evidence citation, `get_architecture` for
boundaries); `ToolSearch("select:mcp__codebase-memory-mcp__...")` loads them.
No index → offer `index_repository` before falling back to Read/Glob/Grep.

Extract:
- imports/requires and calls between modules;
- declared HTTP endpoints and their consumers (fetch/axios/HttpClient/
  RestTemplate/requests) — the consumer edge carries `access: http`;
- queue/event handlers and their publishers — `publish` and `consume`;
- infra triggers declared in config: YAML pipelines, serverless functions,
  workers, cron, systemd timers, k8s CronJob;
- external integrations by instantiated SDK or client.

Ignore vendor, build, dist, cache, node_modules, .git. A language with no
extractor available is not silently dropped: emit `unresolved` with reason
`unindexed-language`.

## Phase 1B — data graph

Implement `DataExtractor` against the detected engine's catalog; the queries per
engine are in `assets/catalog/{postgres,mysql,sqlserver,oracle,sqlite}.sql`.

```
tables()      -> [{ id, schema, name, columns[] }]
routines()    -> [{ id, schema, name, kind, source }]
deps()        -> [{ from, to, type: read|write|call }]
constraints() -> [{ from, to, type: fk }]
jobs()        -> [{ id, schedule, calls[] }]
```

Rules:

1. **The catalog dependency does not distinguish read from write.** Parse each
   routine body with a multi-dialect SQL parser (AST, not regex) and classify
   every access. `scripts/classify_sql.py` does this with sqlglot; feed it
   `routines()` and use its `deps[]` as authoritative, superseding any catalog
   hint (including SQL Server's `is_selected`/`is_updated`).
2. **Scheduled jobs are first-class entrypoints.** They hang off no request and
   are usually the undocumented flows. Model each as `lane: infra, kind: job`
   with a `call` edge into whatever its command invokes.
3. **If the engine exposes no logic** (document store, key-value), the data
   graph is limited to collections and writes are inferred only from
   application code. Record the limit as `engine-exposes-no-logic`.
4. Never degrade to regex. Parser unavailable → every access becomes
   `unresolved` with reason `no-sql-parser`. No credentials → Phase 1B is empty
   and declared with `no-db-credentials`.

Tables and views are `lane: data`, `kind: table|view`. Routines are
`lane: data`, `kind: procedure|package`.

**Carry the catalog detail onto the node, not into the edges.** Phase 4 needs
it and it is lost otherwise:

- `tables().columns[]` → `node.columns = [{ name, type, nullable }]`
- `constraints()` → `node.fks = [{ column, references: { node, column } }]`

An FK is a declared relationship, not a traversal. It lives on the node. It
becomes an edge only when a code path actually follows it, and then the edge
carries the real `call` and its own evidence.

## Phase 1C — code ↔ data suture

Join both graphs by the three paths, in this order of reliability:

| Order | Path | Status |
|---|---|---|
| 1 | Declared ORM mapping (`@Table`/`@Entity`, `DbSet`, migrations) | deterministic |
| 2 | Literal SQL in annotations, `.sql` files or mappers → parse, extract tables | deterministic |
| 3 | SQL built by concatenation or generated at runtime | **not resolved** |

Path 3 never produces an edge. It produces
`{ file, symbol, reason: "dynamic-sql" }` in `unresolved[]`.

Resolving a suture means the application node gets an edge into the concrete
table node with `access: read|write` and evidence pointing at the application
file — not at the database.
