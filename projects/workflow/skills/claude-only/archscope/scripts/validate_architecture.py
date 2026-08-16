#!/usr/bin/env python3
"""Validate an archscope architecture.json. Standard library only.

Usage:
    validate_architecture.py <architecture.json> [--schema=<path>] [--fix-stats]

Exit codes: 0 = valid, 1 = violations found, 2 = usage/IO error.

Checks, in order:
  1. Schema conformance (subset of JSON Schema: type/required/enum/$ref/...).
  2. Referential integrity: every edge endpoint and flow entrypoint is a node id.
  3. Step->edge binding: every step must name an existing edge (from, to, call).
  4. Step ordering: n is 1..len sequential; step n starts where n-1 ended
     unless the step is explicitly marked as a branch.
  5. Stats: recomputed from the graph and compared with the declared values.

Trigger coverage (a flow started by a scheduled job and one by an external
webhook) is reported as a WARNING, never an error: if the repository has no
such entrypoint, inventing one would violate the evidence rule.
"""

import json
import sys
from collections import Counter
from pathlib import Path

DATA_ACCESS = {"read", "write"}
DYNAMIC_REASONS = {"dynamic-sql", "sql-parse-error", "no-sql-parser"}


# --------------------------------------------------------------------------
# Minimal JSON Schema subset validator
# --------------------------------------------------------------------------

def resolve(schema, root):
    seen = 0
    while "$ref" in schema:
        ref = schema["$ref"]
        if not ref.startswith("#/"):
            raise ValueError(f"only local refs supported: {ref}")
        node = root
        for part in ref[2:].split("/"):
            node = node[part]
        schema = node
        seen += 1
        if seen > 20:
            raise ValueError("circular $ref")
    return schema


TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
}


def check_schema(value, schema, root, path, errors):
    schema = resolve(schema, root)

    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: {value!r} not in {schema['enum']}")
        return

    expected = schema.get("type")
    if expected:
        py = TYPES[expected]
        # bool is a subclass of int in Python; keep them distinct.
        ok = isinstance(value, py) and not (
            expected in ("integer", "number") and isinstance(value, bool)
        )
        if not ok:
            errors.append(f"{path}: expected {expected}, got {type(value).__name__}")
            return

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            errors.append(f"{path}: string is empty or shorter than minLength")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: {value} < minimum {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            errors.append(f"{path}: {value} > maximum {schema['maximum']}")

    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            errors.append(f"{path}: fewer than {schema['minItems']} items")
        item_schema = schema.get("items")
        if item_schema:
            for i, item in enumerate(value):
                check_schema(item, item_schema, root, f"{path}[{i}]", errors)

    if isinstance(value, dict):
        props = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{path}: missing required key {key!r}")
        extra = schema.get("additionalProperties", True)
        for key, sub in value.items():
            if key in props:
                check_schema(sub, props[key], root, f"{path}.{key}", errors)
            elif extra is False:
                errors.append(f"{path}: unexpected key {key!r}")
            elif isinstance(extra, dict):
                check_schema(sub, extra, root, f"{path}.{key}", errors)


# --------------------------------------------------------------------------
# Graph-level checks
# --------------------------------------------------------------------------

def check_graph(doc, errors, warnings):
    nodes = doc.get("nodes", [])
    edges = doc.get("edges", [])
    flows = doc.get("flows", [])

    node_ids = set()
    for node in nodes:
        nid = node.get("id")
        if nid in node_ids:
            errors.append(f"nodes: duplicate id {nid!r}")
        node_ids.add(nid)

    edge_ids = set()
    edge_key = {}
    for edge in edges:
        eid = edge.get("id")
        if eid in edge_ids:
            errors.append(f"edges: duplicate id {eid!r}")
        edge_ids.add(eid)
        for side in ("from", "to"):
            if edge.get(side) not in node_ids:
                errors.append(
                    f"edge {eid!r}: {side}={edge.get(side)!r} is not a known node id"
                )
        edge_key[(edge.get("from"), edge.get("to"), edge.get("call"))] = eid

    for flow in flows:
        fid = flow.get("id")
        steps = flow.get("steps", [])

        if flow.get("entrypoint") not in node_ids:
            errors.append(
                f"flow {fid!r}: entrypoint {flow.get('entrypoint')!r} is not a known node id"
            )
        if steps and steps[0].get("from") != flow.get("entrypoint"):
            errors.append(
                f"flow {fid!r}: step 1 starts at {steps[0].get('from')!r}, "
                f"but entrypoint is {flow.get('entrypoint')!r}"
            )

        for i, step in enumerate(steps):
            n = step.get("n")
            label = f"flow {fid!r} step {n}"

            if n != i + 1:
                errors.append(f"{label}: n should be {i + 1}, steps must be 1..N in order")

            key = (step.get("from"), step.get("to"), step.get("call"))
            if key not in edge_key:
                errors.append(
                    f"{label}: no edge matches "
                    f"{step.get('from')!r} -> {step.get('to')!r} call={step.get('call')!r}. "
                    f"Discard the whole flow."
                )

            if i > 0 and not step.get("branch"):
                prev_to = steps[i - 1].get("to")
                if step.get("from") != prev_to:
                    errors.append(
                        f"{label}: starts at {step.get('from')!r} but step {i} ended at "
                        f"{prev_to!r}; chain them or mark this step as a branch"
                    )

    triggers = {f.get("trigger") for f in flows}
    for required, human in (("job", "a scheduled job"), ("webhook", "an external webhook")):
        if required not in triggers:
            warnings.append(
                f"no flow is triggered by {human}. Confirm none exists in the "
                f"repository — do not invent one."
            )


def compute_stats(doc):
    nodes = doc.get("nodes", [])
    edges = doc.get("edges", [])
    node_lane = {n.get("id"): n.get("lane") for n in nodes}

    resolved = sum(
        1
        for e in edges
        if e.get("access") in DATA_ACCESS and node_lane.get(e.get("to")) == "data"
    )
    dynamic = sum(1 for u in doc.get("unresolved", []) if u.get("reason") in DYNAMIC_REASONS)
    total = resolved + dynamic

    return {
        "nodes_by_lane": dict(sorted(Counter(n.get("lane") for n in nodes).items())),
        "edges_by_access": dict(sorted(Counter(e.get("access") for e in edges).items())),
        "data_access": {
            "resolved": resolved,
            "dynamic": dynamic,
            "pct_resolved": round(100.0 * resolved / total, 1) if total else 100.0,
        },
        "flows": len(doc.get("flows", [])),
    }


def check_stats(doc, errors, fix):
    actual = compute_stats(doc)
    declared = doc.setdefault("stats", {})
    for key, value in actual.items():
        if key == "flows" and "flows" not in declared:
            continue  # optional field: only checked when the author declared it
        if declared.get(key) != value:
            if fix:
                declared[key] = value
            else:
                errors.append(
                    f"stats.{key}: declared {declared.get(key)!r}, recomputed {value!r}"
                )


DEFAULT_SCHEMA = Path(__file__).resolve().parent.parent / "assets" / "architecture.schema.json"


def main(argv):
    argv = argv[1:]
    flags = {a for a in argv if a.startswith("--") and "=" not in a}
    options = dict(a[2:].split("=", 1) for a in argv if a.startswith("--") and "=" in a)
    args = [a for a in argv if not a.startswith("--")]

    if len(args) != 1:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    target = Path(args[0])
    schema_path = Path(options.get("schema", DEFAULT_SCHEMA))

    try:
        doc = json.loads(target.read_text(encoding="utf-8"))
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR reading input: {exc}", file=sys.stderr)
        return 2

    fix = "--fix-stats" in flags
    errors, warnings = [], []

    # Recompute stats before schema validation when repairing, otherwise a
    # missing stats block fails the schema and the repair never runs.
    if fix:
        doc.setdefault("stats", {}).update(compute_stats(doc))

    check_schema(doc, schema, schema, "$", errors)
    if not errors:
        # Graph checks assume the shape is already sound.
        check_graph(doc, errors, warnings)
        check_stats(doc, errors, fix)

    for warning in warnings:
        print(f"WARN  {warning}")

    if errors:
        for error in errors:
            print(f"FAIL  {error}")
        print(f"\n{len(errors)} violation(s). architecture.json is NOT valid.")
        return 1

    if fix:
        target.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"stats recomputed and written to {target}")

    stats = doc.get("stats", {})
    print(
        f"OK  {len(doc.get('nodes', []))} nodes, {len(doc.get('edges', []))} edges, "
        f"{len(doc.get('flows', []))} flows, {len(doc.get('unresolved', []))} unresolved, "
        f"{stats.get('data_access', {}).get('pct_resolved')}% data access resolved."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
