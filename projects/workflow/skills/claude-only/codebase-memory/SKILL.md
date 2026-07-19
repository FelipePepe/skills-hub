---
name: codebase-memory
description: "Structural code queries via the codebase knowledge graph. Trigger: explore the codebase, architecture, who calls X, trace call chain, dependencies, impact analysis, dead code, refactor candidates, Cypher/graph queries."
---

# Codebase Memory — Knowledge Graph Tools

Graph tools return precise structural results in ~500 tokens vs ~80K for grep.

## Quick Decision Matrix

| Question | Tool call |
|----------|----------|
| Who calls X? | `trace_path(direction="inbound")` |
| What does X call? | `trace_path(direction="outbound")` |
| Full call context | `trace_path(direction="both")` |
| Find by name pattern | `search_graph(name_pattern="...")` |
| Dead code | `search_graph(max_degree=0, exclude_entry_points=true)` |
| Cross-service edges | `query_graph` with Cypher |
| Impact of local changes | `detect_changes()` |
| Risk-classified trace | `trace_path(risk_labels=true)` |
| Text search | `search_code` or Grep |

## Exploration Workflow
1. `list_projects` — check if project is indexed
2. `get_graph_schema` — understand node/edge types
3. `search_graph(label="Function", name_pattern=".*Pattern.*")` — find code
4. `get_code_snippet(qualified_name="project.path.FuncName")` — read source

## Tracing Workflow
1. `search_graph(name_pattern=".*FuncName.*")` — discover exact name
2. `trace_path(function_name="FuncName", direction="both", depth=3)` — trace
3. `detect_changes()` — map git diff to affected symbols

## Quality Analysis
- Dead code: `search_graph(max_degree=0, exclude_entry_points=true)`
- High fan-out: `search_graph(min_degree=10, relationship="CALLS", direction="outbound")`
- High fan-in: `search_graph(min_degree=10, relationship="CALLS", direction="inbound")`

## 14 MCP Tools
`index_repository`, `index_status`, `list_projects`, `delete_project`,
`search_graph`, `search_code`, `trace_path`, `detect_changes`,
`query_graph`, `get_graph_schema`, `get_code_snippet`, `get_architecture`,
`manage_adr`, `ingest_traces`

## Edge Types
CALLS, HTTP_CALLS, ASYNC_CALLS, IMPORTS, DEFINES, DEFINES_METHOD,
HANDLES, IMPLEMENTS, OVERRIDE, USAGE, FILE_CHANGES_WITH,
CONTAINS_FILE, CONTAINS_FOLDER, CONTAINS_PACKAGE

## Cypher Examples (for query_graph)
```
MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20
MATCH (f:Function) WHERE f.name =~ '.*Handler.*' RETURN f.name, f.file_path
MATCH (a)-[r:CALLS]->(b) WHERE a.name = 'main' RETURN b.name
```

## Persisting Findings (Engram)

Graph queries are cheap to re-run, but the *conclusion* of an exploration is worth keeping so the next session doesn't redo the same traversal. After a non-trivial finding — dead code list, high fan-out/fan-in hotspot, cross-service dependency, an ADR-worthy structural decision — save it:

- `mem_search("<topic>", project=<X>)` first to check it isn't already recorded.
- `mem_save`/`mem_update` with `topic_key` scoped to the project, e.g. `token-optimizer/dead-code-audit`, `token-optimizer/high-fanout-parser`.
- Don't save routine single-lookup results (e.g. "who calls X") — only findings that took real traversal/analysis to produce and would be expensive to redo.

## Compressing Large Results (Headroom)

See the `headroom` skill for full tool docs (`headroom_compress`/`headroom_retrieve`/`headroom_stats`). Applied here:

`query_graph`, `get_architecture`, and `search_code` can return large payloads (wide Cypher results, big architecture dumps, many text matches).

- If a result is large (roughly >200 lines / clearly verbose), run `headroom_compress` on it before carrying it forward in context, instead of pasting the raw payload.
- If a compressed version of the same query was produced earlier in the session, prefer `headroom_retrieve` over re-querying and re-compressing.
- Small, targeted results (a handful of rows/snippets) don't need this — compressing them costs more than it saves.
- Headroom unavailable → fall back to using the raw tool output directly; do not block the exploration on it.

## Gotchas
1. `search_graph(relationship="HTTP_CALLS")` filters nodes by degree — use `query_graph` with Cypher to see actual edges.
2. `query_graph` has a 200-row cap — use `search_graph` with degree filters for counting.
3. `trace_path` needs exact names — use `search_graph(name_pattern=...)` first.
4. `direction="outbound"` misses cross-service callers — use `direction="both"`.
5. Results default to 10 per page — check `has_more` and use `offset`.
