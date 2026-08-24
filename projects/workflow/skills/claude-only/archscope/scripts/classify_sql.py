#!/usr/bin/env python3
"""Classify routine-body table accesses as read | write | call, from the SQL AST.

The engine catalog records that routine R depends on table T, but never whether
it reads or writes it. This script recovers that by parsing each routine body
with sqlglot and walking the tree. There is no regex fallback: a body that does
not parse becomes an `unresolved` entry, never a guess.

Usage:
    classify_sql.py < input.json > output.json
    uvx --from sqlglot --with sqlglot python classify_sql.py < input.json

Input (stdin, JSON):
    {
      "dialect": "postgres",
      "routines": [
        {"id": "public.sp_close_day", "schema": "public", "name": "sp_close_day",
         "kind": "procedure", "source": "CREATE PROCEDURE ...", "file": "db://..."}
      ]
    }

Output (stdout, JSON):
    {
      "deps": [{"from": "<routine id>", "to": "<table or routine>", "type": "read|write|call"}],
      "unresolved": [{"file": "...", "symbol": "...", "reason": "sql-parse-error", "detail": "..."}],
      "stats": {"routines": 12, "parsed": 11, "failed": 1}
    }

Exit codes: 0 = done, 2 = bad input, 3 = sqlglot unavailable.
"""

import json
import sys

try:
    import sqlglot
    from sqlglot import exp
except ImportError:
    json.dump(
        {
            "error": "sqlglot-unavailable",
            "hint": "install it (pip install sqlglot) or run via `uvx --with sqlglot python ...`. "
                    "Do NOT fall back to regex: emit every access as unresolved "
                    "with reason 'no-sql-parser' instead.",
        },
        sys.stdout,
    )
    sys.stdout.write("\n")
    sys.exit(3)


# DML nodes whose target table is written, mapped to the attribute holding it.
WRITE_TARGETS = (exp.Insert, exp.Update, exp.Delete, exp.Merge)


def target_table(node):
    """Return the Table a DML node writes to, unwrapping INSERT INTO t (cols)."""
    this = node.this
    if isinstance(this, exp.Schema):  # INSERT INTO t (a, b)
        this = this.this
    return this if isinstance(this, exp.Table) else None


def cte_names(tree):
    """Names bound by WITH clauses — these are not real tables."""
    names = set()
    for cte in tree.find_all(exp.CTE):
        alias = cte.alias_or_name
        if alias:
            names.add(alias.lower())
    return names


def literal_text(node):
    """Return the raw SQL text of a routine body carried as a string node."""
    if isinstance(node, exp.Heredoc) or (isinstance(node, exp.Literal) and node.is_string):
        inner = node.this
        if isinstance(inner, str):
            return inner
        if inner is not None and isinstance(getattr(inner, "this", None), str):
            return inner.this
    return None


def body_statements(statement, dialect):
    """Split a routine into (body statements, names that are the routine itself).

    Engines return routine sources in two shapes. Postgres/MySQL hand back the
    body only, or a CREATE whose body is a dollar-quoted string that sqlglot
    keeps as an opaque Heredoc — that text must be parsed separately or every
    access inside it is lost. SQL Server/Oracle inline the body in the AST, so
    the wrapper itself is walkable; there only the routine's own identifier has
    to be filtered out, since sqlglot models it as a Table.
    """
    if not isinstance(statement, exp.Create):
        return [statement], set()

    own = set()
    if statement.this is not None:
        own = {exp.table_name(t).lower() for t in statement.this.find_all(exp.Table)}

    text = literal_text(statement.args.get("expression"))
    if text and text.strip():
        return [s for s in sqlglot.parse(text, dialect=dialect) if s], own

    return [statement], own


def classify(tree, known_routines, excluded):
    """Return (reads, writes, calls) as sets of resolved identifiers."""
    locals_ = cte_names(tree) | excluded
    writes, reads, calls = set(), set(), set()

    for node in tree.find_all(*WRITE_TARGETS):
        table = target_table(node)
        if table is not None:
            name = exp.table_name(table)
            if name.lower() not in locals_:
                writes.add(name)

    # TRUNCATE / CREATE TABLE AS / DROP arrive as Command or DDL nodes.
    for node in tree.find_all(exp.Create, exp.Drop):
        if isinstance(node.this, (exp.Table, exp.Schema)):
            table = node.this.this if isinstance(node.this, exp.Schema) else node.this
            if isinstance(table, exp.Table):
                name = exp.table_name(table)
                if name.lower() not in locals_:
                    writes.add(name)

    for table in tree.find_all(exp.Table):
        name = exp.table_name(table)
        if name.lower() in locals_ or name in writes:
            continue
        reads.add(name)

    for node in tree.find_all(exp.Anonymous, exp.Func):
        name = (getattr(node, "name", "") or "").lower()
        if name and name in known_routines:
            calls.add(known_routines[name])

    return reads, writes, calls


def main():
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        print(f"ERROR: stdin is not valid JSON: {exc}", file=sys.stderr)
        return 2

    dialect = payload.get("dialect") or None
    routines = payload.get("routines", [])
    if not isinstance(routines, list):
        print("ERROR: 'routines' must be a list", file=sys.stderr)
        return 2

    known = {}
    for routine in routines:
        name = (routine.get("name") or "").lower()
        if name:
            known[name] = routine.get("id")

    deps, unresolved = [], []
    parsed_count = 0

    for routine in routines:
        rid = routine.get("id")
        source = routine.get("source") or ""
        origin = routine.get("file") or f"db://{rid}"

        if not source.strip():
            unresolved.append({
                "file": origin,
                "symbol": rid,
                "reason": "engine-exposes-no-logic",
                "detail": "catalog returned an empty routine body",
            })
            continue

        try:
            statements = [s for s in sqlglot.parse(source, dialect=dialect) if s]
        except Exception as exc:  # sqlglot raises several distinct error types
            unresolved.append({
                "file": origin,
                "symbol": rid,
                "reason": "sql-parse-error",
                "detail": f"{type(exc).__name__}: {exc}".replace("\n", " ")[:300],
            })
            continue

        parsed_count += 1
        reads, writes, calls = set(), set(), set()
        try:
            for statement in statements:
                body, own = body_statements(statement, dialect)
                for inner in body:
                    r, w, c = classify(inner, known, own)
                    reads |= r
                    writes |= w
                    calls |= c
        except Exception as exc:
            parsed_count -= 1
            unresolved.append({
                "file": origin,
                "symbol": rid,
                "reason": "sql-parse-error",
                "detail": f"body: {type(exc).__name__}: {exc}".replace("\n", " ")[:300],
            })
            continue

        reads -= writes           # a table written in the body counts as a write
        calls.discard(rid)        # ignore self-recursion

        for target in sorted(writes):
            deps.append({"from": rid, "to": target, "type": "write"})
        for target in sorted(reads):
            deps.append({"from": rid, "to": target, "type": "read"})
        for target in sorted(t for t in calls if t):
            deps.append({"from": rid, "to": target, "type": "call"})

    json.dump(
        {
            "deps": deps,
            "unresolved": unresolved,
            "stats": {
                "routines": len(routines),
                "parsed": parsed_count,
                "failed": len(routines) - parsed_count,
            },
        },
        sys.stdout,
        indent=2,
        ensure_ascii=False,
    )
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
