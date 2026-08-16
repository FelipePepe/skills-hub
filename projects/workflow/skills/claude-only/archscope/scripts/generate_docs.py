#!/usr/bin/env python3
"""Generate the archscope documentation tree from architecture.json.

Usage:
    generate_docs.py <architecture.json> [--out=docs/archscope] [--force]
    generate_docs.py --check [--out=docs/archscope]

Exit codes: 0 = done, 1 = check failed / refused to overwrite, 2 = usage or IO.

Everything structural — counts, traversal tables, reader/writer lists, relative
links — is computed here, never written by hand: with dozens of component pages
the cross-links are the first thing that drifts. Judgement is left to the model
through explicit `[[FILL:kind]]` markers, and `--check` refuses to call the tree
finished while any marker survives.

No fact is introduced that does not derive from nodes, edges, flows, unresolved
or stats. Missing information is written as missing.
"""

import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

VERSION = "1.1"
MARKER = "[[FILL:%s]]"

DATA_KINDS = {"table", "view"}
ROUTINE_KINDS = {"procedure", "package", "function"}

TRIGGER_LABEL = {
    "ui": "Interfaz de usuario",
    "api": "Llamada API",
    "job": "Job planificado",
    "webhook": "Webhook externo",
    "queue": "Consumo de cola",
    "cli": "CLI",
}

# `reason` is a closed enum, so the remediation text is a lookup, not a guess.
REMEDIATION = {
    "dynamic-sql":
        "Sustituir la construcción por concatenación por SQL literal o por el ORM, "
        "o registrar manualmente la tabla destino. Resolver esto requiere ejecución "
        "simbólica, no análisis estático.",
    "dynamic-import":
        "Sustituir el import dinámico por uno estático, o declarar el mapa de módulos "
        "cargables en configuración para que sea extraíble.",
    "dynamic-dispatch":
        "Anotar el conjunto de implementaciones posibles, o registrar el dispatch en "
        "un mapa explícito.",
    "sql-parse-error":
        "Revisar el dialecto pasado al parser y la sintaxis del cuerpo. Si es SQL "
        "válido que sqlglot no cubre, abrir incidencia con el fragmento mínimo.",
    "no-sql-parser":
        "Instalar sqlglot (`pip install sqlglot`) o ejecutar vía "
        "`uvx --with sqlglot python`. Sin parser no se clasifica ningún acceso.",
    "no-db-credentials":
        "Facilitar credenciales de solo lectura sobre el catálogo, o un volcado del "
        "esquema, y volver a ejecutar la Fase 1B.",
    "engine-exposes-no-logic":
        "Limitación del motor, no del análisis. Las escrituras solo pueden inferirse "
        "desde el código de aplicación.",
    "external-binary":
        "El comportamiento vive en un binario externo. Documentar su contrato a mano "
        "o excluirlo explícitamente del alcance.",
    "generated-code":
        "Analizar el generador y su plantilla en lugar de la salida generada.",
    "unindexed-language":
        "Añadir un extractor para ese lenguaje, o declarar el módulo fuera de alcance.",
}


# ----------------------------------------------------------------- helpers

def slug(value):
    out = re.sub(r"[^A-Za-z0-9._-]+", "-", str(value)).strip("-.")
    return out or "sin-id"


def cell(value):
    """Escape a value so it cannot break out of a markdown table cell."""
    return str("" if value is None else value).replace("|", "\\|").replace("\n", " ")


def code(value):
    return "`%s`" % cell(value) if value not in (None, "") else "—"


def link(from_file, to_file, text):
    rel = os.path.relpath(to_file, from_file.parent)
    return "[%s](%s)" % (cell(text), rel.replace(os.sep, "/"))


def fill(kind, hint):
    return "%s %s" % (MARKER % kind, hint)


def table(headers, rows):
    if not rows:
        return "_Ninguno._\n"
    out = ["| " + " | ".join(headers) + " |",
           "|" + "|".join("---" for _ in headers) + "|"]
    out += ["| " + " | ".join(cell(c) for c in row) + " |" for row in rows]
    return "\n".join(out) + "\n"


# ----------------------------------------------------------------- model

class Model:
    def __init__(self, doc, root):
        self.doc = doc
        self.root = root
        self.nodes = doc.get("nodes", [])
        self.edges = doc.get("edges", [])
        self.flows = doc.get("flows", [])
        self.unresolved = doc.get("unresolved", [])
        self.stats = doc.get("stats", {})
        self.meta = doc.get("meta", {})

        self.by_id = {n["id"]: n for n in self.nodes}
        self.out_edges = defaultdict(list)
        self.in_edges = defaultdict(list)
        for e in self.edges:
            self.out_edges[e["from"]].append(e)
            self.in_edges[e["to"]].append(e)

        self.edge_by_key = {}
        for e in self.edges:
            self.edge_by_key[(e["from"], e["to"], e["call"])] = e

        # flows a node participates in
        self.node_flows = defaultdict(list)
        for f in self.flows:
            touched = set()
            for s in f.get("steps", []):
                touched.add(s["from"])
                touched.add(s["to"])
            for nid in touched:
                self.node_flows[nid].append(f)

    # -- paths
    def p(self, *parts):
        return self.root.joinpath(*parts)

    def flow_path(self, f):
        return self.p("escenarios", slug(f["id"]) + ".md")

    def node_path(self, n):
        return self.p("componentes", slug(n["id"]) + ".md")

    def documented(self, nid):
        """Component pages exist only for lane != external."""
        n = self.by_id.get(nid)
        return n is not None and n.get("lane") != "external"

    def label(self, nid):
        n = self.by_id.get(nid)
        return n["label"] if n else nid

    def ref(self, from_file, nid):
        """Link to a node's page, or plain text when it has none."""
        n = self.by_id.get(nid)
        if n is None:
            return "`%s` (nodo desconocido)" % cell(nid)
        if self.documented(nid):
            return link(from_file, self.node_path(n), n["label"])
        return "%s (externo, ver %s)" % (
            cell(n["label"]), link(from_file, self.p("integraciones.md"), "integraciones"))

    def step_edge(self, s):
        return self.edge_by_key.get((s["from"], s["to"], s["call"]))

    def access_of(self, s):
        e = self.step_edge(s)
        return e["access"] if e else None

    def evidence_of(self, s):
        e = self.step_edge(s)
        ev = dict(s.get("evidence") or {})
        if e and e.get("evidence", {}).get("line") and "line" not in ev:
            ev["line"] = e["evidence"]["line"]
        return ev

    def header(self, title):
        m = self.meta
        commit = m.get("commit")
        dirty = m.get("dirty")
        when = m.get("generated_at")
        repo = m.get("repo")
        bits = [
            "commit `%s`" % commit if commit else "commit **no registrado**",
            ("árbol de trabajo sucio" if dirty else "árbol de trabajo limpio")
            if dirty is not None else "estado del árbol **no registrado**",
            when if when else "fecha **no registrada**",
            "extractor archscope %s" % VERSION,
        ]
        head = "# %s\n\n" % title
        head += "> Generado desde %s%s\n" % (
            (("`%s` · " % repo) if repo else ""), " · ".join(bits))
        head += "> Fuente única: `architecture.json`. Generado; no editar a mano.\n\n"
        return head


# ----------------------------------------------------------------- pages

def page_readme(m):
    f = m.p("README.md")
    s = m.header("Documentación de arquitectura")

    s += "## Mapa de lectura\n\n"
    s += "Recorre los documentos en este orden; los escenarios están ordenados por "
    s += "valor de onboarding, no por orden de descubrimiento.\n\n"
    s += "1. %s — lanes, recuentos y entrypoints.\n" % link(
        f, m.p("01-vision-general.md"), "Visión general")
    s += "2. **Escenarios** — cada flujo de negocio extremo a extremo:\n"
    for fl in m.flows:
        s += "   - %s%s\n" % (
            link(f, m.flow_path(fl), fl["title"]),
            (" — " + cell(fl.get("subtitle"))) if fl.get("subtitle") else "")
    if not m.flows:
        s += "   - _Ningún flujo superó la validación._\n"
    s += "3. **Componentes** — una ficha por nodo (%d). Índice en %s.\n" % (
        sum(1 for n in m.nodes if n.get("lane") != "external"),
        link(f, m.p("01-vision-general.md"), "visión general"))
    s += "4. %s — tablas, FKs, lectores y escritores.\n" % link(
        f, m.p("datos", "modelo.md"), "Modelo de datos")
    s += "5. %s — sistemas externos y quién los invoca.\n" % link(
        f, m.p("integraciones.md"), "Integraciones")
    s += "6. %s — lo que el análisis no pudo resolver.\n" % link(
        f, m.p("huecos.md"), "Huecos")
    s += "7. %s — términos de dominio y dónde aparecen.\n\n" % link(
        f, m.p("glosario.md"), "Glosario")

    da = m.stats.get("data_access", {})
    s += "## De un vistazo\n\n"
    s += table(["Métrica", "Valor"], [
        ["Nodos", len(m.nodes)],
        ["Aristas", len(m.edges)],
        ["Escenarios validados", len(m.flows)],
        ["Elementos sin resolver", len(m.unresolved)],
        ["Accesos a datos resueltos",
         "%s%%" % da.get("pct_resolved") if da.get("pct_resolved") is not None else "no calculado"],
    ])
    s += "\nLos huecos son parte del entregable: leer "
    s += link(f, m.p("huecos.md"), "huecos.md")
    s += " antes de tomar decisiones de impacto.\n"
    return f, s


def page_overview(m):
    f = m.p("01-vision-general.md")
    s = m.header("Visión general")

    lanes = Counter(n.get("lane") for n in m.nodes)
    kinds = Counter(n.get("kind") for n in m.nodes)

    s += "## Recuento por lane\n\n"
    s += table(["Lane", "Nodos"], [[k, v] for k, v in sorted(lanes.items())])
    s += "\n## Recuento por kind\n\n"
    s += table(["Kind", "Nodos"], [[k, v] for k, v in sorted(kinds.items())])

    s += "\n## Entrypoints\n\n"
    s += "Nodos que inician un escenario, más los que no reciben ninguna arista.\n\n"
    entry = {fl["entrypoint"] for fl in m.flows}
    orphan = {n["id"] for n in m.nodes if not m.in_edges[n["id"]]}
    rows = []
    for nid in sorted(entry | orphan):
        n = m.by_id.get(nid)
        if not n:
            continue
        origin = []
        if nid in entry:
            origin.append("entrypoint de escenario")
        if nid in orphan:
            origin.append("sin aristas entrantes")
        rows.append([m.ref(f, nid), n.get("lane"), n.get("kind"), " / ".join(origin)])
    s += table(["Nodo", "Lane", "Kind", "Por qué"], rows)

    s += "\n## Índice de componentes\n\n"
    for lane in ["client", "frontend", "backend", "infra", "data"]:
        group = sorted((n for n in m.nodes if n.get("lane") == lane),
                       key=lambda n: n["id"])
        if not group:
            continue
        s += "### %s\n\n" % lane
        s += table(["Componente", "Kind", "Subtítulo"],
                   [[m.ref(f, n["id"]), n.get("kind"), n.get("subtitle") or "—"]
                    for n in group])
        s += "\n"

    s += "## Preguntas abiertas\n\n"
    s += fill("preguntas-vision",
              "Comportamientos que parecen deliberados pero no están justificados en "
              "el código. Si no hay ninguno, escribe «Ninguna».") + "\n"
    return f, s


def page_flow(m, fl):
    f = m.flow_path(fl)
    s = m.header(fl["title"])
    if fl.get("subtitle"):
        s += "_%s_\n\n" % cell(fl["subtitle"])

    s += "## Resumen\n\n"
    s += fill("resumen-flujo",
              "3-5 líneas en lenguaje de negocio sobre qué consigue este flujo. "
              "Deriva de los pasos y sus descripciones; no añadas intención que no "
              "esté escrita en el código.") + "\n\n"

    trigger = fl.get("trigger")
    s += "## Entrypoint\n\n"
    s += "- **Disparador:** %s\n" % (TRIGGER_LABEL.get(trigger, "no registrado"))
    s += "- **Nodo inicial:** %s\n" % m.ref(f, fl["entrypoint"])
    ev0 = m.evidence_of(fl["steps"][0]) if fl.get("steps") else {}
    if ev0:
        s += "- **Evidencia:** `%s`%s\n" % (
            cell(ev0.get("file")),
            (" · `%s`" % cell(ev0.get("symbol"))) if ev0.get("symbol") else "")
    s += "\n"

    s += "## Recorrido\n\n"
    rows = []
    for st in fl.get("steps", []):
        rows.append([st["n"], m.ref(f, st["from"]), m.ref(f, st["to"]),
                     code(st["call"]), m.access_of(st) or "—"])
    s += table(["#", "Origen", "Destino", "Llamada", "Acceso"], rows)

    s += "\n## Detalle por paso\n\n"
    for st in fl.get("steps", []):
        ev = m.evidence_of(st)
        acc = m.access_of(st)
        s += "### %d. %s → %s\n\n" % (st["n"], m.label(st["from"]), m.label(st["to"]))
        s += "%s\n\n" % cell(st.get("description"))
        s += "- **Llamada:** %s\n" % code(st["call"])
        s += "- **Acceso:** %s\n" % (acc or "no registrado")
        s += "- **Evidencia:** `%s`%s%s\n" % (
            cell(ev.get("file")),
            (" · `%s`" % cell(ev.get("symbol"))) if ev.get("symbol") else "",
            (" · línea %s" % ev["line"]) if ev.get("line") else "")
        if acc == "write":
            s += "- **Escribe en:** %s\n" % m.ref(f, st["to"])
        elif acc == "read":
            s += "- **Lee de:** %s\n" % m.ref(f, st["to"])
        else:
            s += "- **Qué devuelve:** %s\n" % fill(
                "retorno-%d" % st["n"],
                "Solo si es visible en `%s`; si no, escribe «no visible en el código citado»."
                % cell(ev.get("file")))
        s += "\n"

    s += "## Efectos en datos\n\n"
    writes = [st for st in fl.get("steps", []) if m.access_of(st) == "write"]
    reads = [st for st in fl.get("steps", []) if m.access_of(st) == "read"]
    if writes:
        s += "Tablas escritas por este flujo:\n\n"
        s += table(["Paso", "Tabla", "Llamada"],
                   [[st["n"], m.ref(f, st["to"]), code(st["call"])] for st in writes])
    else:
        s += "_Este flujo no escribe en ninguna tabla._\n"
    if reads:
        s += "\nTablas leídas:\n\n"
        s += table(["Paso", "Tabla", "Llamada"],
                   [[st["n"], m.ref(f, st["to"]), code(st["call"])] for st in reads])
    s += "\n"

    s += "## Dependencias externas\n\n"
    ext = []
    for st in fl.get("steps", []):
        for nid in (st["from"], st["to"]):
            n = m.by_id.get(nid)
            if n and n.get("lane") == "external" and nid not in [e[0] for e in ext]:
                ext.append((nid, st["n"]))
    if ext:
        s += table(["Sistema", "Paso"],
                   [[m.ref(f, nid), n] for nid, n in ext])
        s += "\n" + fill(
            "fallo-externo",
            "Para cada sistema, qué ocurre si falla — **solo** si hay manejo de error "
            "visible en los `evidence.file` ya citados por este flujo. Si no lo hay, "
            "escribe explícitamente que no hay manejo de error visible.") + "\n"
    else:
        s += "_Este flujo no toca ningún sistema externo._\n"

    s += "\n## Riesgos observables\n\n"
    candidates = []
    if len(writes) >= 2:
        candidates.append(
            "**Escrituras múltiples** — pasos %s escriben en %d tablas distintas. "
            "Verificar si comparten transacción." % (
                ", ".join(str(st["n"]) for st in writes),
                len({st["to"] for st in writes})))
    if ext:
        candidates.append(
            "**Llamada externa** — pasos %s cruzan un límite de red. Verificar "
            "timeout y reintentos." % ", ".join(str(n) for _, n in ext))
    cross_file = {m.evidence_of(st).get("file") for st in writes}
    if len(cross_file) > 1:
        candidates.append(
            "**Escrituras repartidas entre ficheros** — %s. Una transacción que "
            "abarque varios ficheros es más frágil de verificar." % ", ".join(
                "`%s`" % cell(x) for x in sorted(c for c in cross_file if c)))
    if candidates:
        s += "Candidatos detectados a partir del grafo. **Confirma o descarta cada uno "
        s += "releyendo únicamente los ficheros ya citados arriba**; no abras ficheros "
        s += "que este flujo no cite.\n\n"
        for c in candidates:
            s += "- %s\n" % c
        s += "\n" + fill("riesgos",
                         "Veredicto por candidato, con la línea concreta que lo "
                         "confirma o descarta. Si no es verificable, dilo.") + "\n"
    else:
        s += "_El grafo no expone ningún candidato a riesgo en este flujo._\n"

    s += "\n## Preguntas abiertas\n\n"
    s += fill("preguntas-flujo",
              "Comportamiento que parece deliberado pero no está justificado en el "
              "código. «Ninguna» si no aplica.") + "\n"
    return f, s


def page_component(m, n):
    f = m.node_path(n)
    s = m.header(n["label"])
    s += "- **id:** `%s`\n- **lane:** %s\n- **kind:** %s\n" % (
        cell(n["id"]), n.get("lane"), n.get("kind"))
    if n.get("subtitle"):
        s += "- **subtítulo:** %s\n" % cell(n["subtitle"])
    s += "\n"

    outs = sorted(m.out_edges[n["id"]], key=lambda e: (e["to"], e["call"]))
    ins = sorted(m.in_edges[n["id"]], key=lambda e: (e["from"], e["call"]))

    s += "## Responsabilidad\n\n"
    s += fill("responsabilidad",
              "Infiere la responsabilidad de sus %d aristas salientes y %d entrantes. "
              "Marca la inferencia: «Inferido de las aristas X e Y». No describas "
              "intención de negocio que no esté en el código."
              % (len(outs), len(ins))) + "\n\n"

    s += "## Archivos\n\n"
    if n.get("files"):
        for path in n["files"]:
            s += "- `%s`\n" % cell(path)
    else:
        s += "_Ninguno registrado._\n"
    s += "\n"

    s += "## Consume\n\n"
    s += table(["Destino", "Llamada", "Acceso", "Evidencia"],
               [[m.ref(f, e["to"]), code(e["call"]), e["access"],
                 "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in outs])

    s += "\n## Es consumido por\n\n"
    s += table(["Origen", "Llamada", "Acceso", "Evidencia"],
               [[m.ref(f, e["from"]), code(e["call"]), e["access"],
                 "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in ins])

    s += "\n## Participa en los escenarios\n\n"
    fls = m.node_flows.get(n["id"], [])
    if fls:
        for fl in fls:
            s += "- %s\n" % link(f, m.flow_path(fl), fl["title"])
    else:
        s += "_En ninguno._\n"
    s += "\n"

    if n.get("lane") == "data":
        s += "## Estructura\n\n"
        if n.get("columns"):
            s += table(["Columna", "Tipo", "Nullable"],
                       [[c["name"], c.get("type") or "—",
                         "sí" if c.get("nullable") else "no"] for c in n["columns"]])
        else:
            s += "_Columnas no registradas en `architecture.json`._\n"

        s += "\n### Claves foráneas salientes\n\n"
        s += table(["Columna", "Referencia"],
                   [[fk["column"], "%s.%s" % (
                       m.label(fk["references"]["node"]),
                       fk["references"].get("column") or "?")]
                    for fk in n.get("fks", [])])

        s += "\n### Claves foráneas entrantes\n\n"
        incoming_fks = []
        for other in m.nodes:
            for fk in other.get("fks", []) or []:
                if fk["references"]["node"] == n["id"]:
                    incoming_fks.append([m.ref(f, other["id"]), fk["column"]])
        s += table(["Desde", "Columna"], incoming_fks)

        s += "\n## Análisis de impacto\n\n"
        readers = [e for e in ins if e["access"] == "read"]
        writers = [e for e in ins if e["access"] == "write"]
        s += "### Lectores (%d)\n\n" % len(readers)
        s += table(["Componente", "Llamada", "Evidencia"],
                   [[m.ref(f, e["from"]), code(e["call"]),
                     "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in readers])
        s += "\n### Escritores (%d)\n\n" % len(writers)
        s += table(["Componente", "Llamada", "Evidencia"],
                   [[m.ref(f, e["from"]), code(e["call"]),
                     "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in writers])
        distinct_writers = len({e["from"] for e in writers})
        if distinct_writers > 1:
            s += ("\n> **Escritores múltiples.** %d componentes distintos escriben "
                  "aquí: es un punto de acoplamiento real y cualquier cambio de "
                  "forma los afecta a todos.\n" % distinct_writers)
        s += "\n"

    s += "## Preguntas abiertas\n\n"
    s += fill("preguntas-componente", "«Ninguna» si no aplica.") + "\n"
    return f, s


def page_data_model(m):
    f = m.p("datos", "modelo.md")
    s = m.header("Modelo de datos")

    tables = sorted((n for n in m.nodes
                     if n.get("lane") == "data" and n.get("kind") in DATA_KINDS),
                    key=lambda n: n["id"])
    if not tables:
        s += "_No se extrajo ninguna tabla ni vista. Revisa %s._\n" % link(
            f, m.p("huecos.md"), "huecos.md")
        return f, s

    coupling = []
    for n in tables:
        writers = {e["from"] for e in m.in_edges[n["id"]] if e["access"] == "write"}
        if len(writers) > 1:
            coupling.append((n, writers))

    s += "## Puntos de acoplamiento\n\n"
    if coupling:
        s += "Tablas con más de un escritor. Son los puntos donde un cambio de forma "
        s += "se propaga a varios componentes a la vez.\n\n"
        s += table(["Tabla", "Escritores"],
                   [[m.ref(f, n["id"]),
                     ", ".join(sorted(m.label(w) for w in ws))] for n, ws in coupling])
    else:
        s += "_Ninguna tabla tiene más de un escritor._\n"
    s += "\n"

    for n in tables:
        ins = m.in_edges[n["id"]]
        readers = sorted({m.label(e["from"]) for e in ins if e["access"] == "read"})
        writers = sorted({m.label(e["from"]) for e in ins if e["access"] == "write"})
        routines = sorted({m.label(e["from"]) for e in ins
                           if (m.by_id.get(e["from"]) or {}).get("kind") in ROUTINE_KINDS})
        fls = m.node_flows.get(n["id"], [])

        s += "## %s\n\n" % cell(n["label"])
        s += "- **id:** `%s` · **kind:** %s\n" % (cell(n["id"]), n.get("kind"))
        s += "- **Ficha:** %s\n\n" % link(f, m.node_path(n), n["label"])
        s += "**Propósito.** %s\n\n" % fill(
            "proposito-%s" % slug(n["id"]),
            "Inferido de sus columnas y de quién la escribe. Marca la inferencia y "
            "no inventes semántica de negocio.")

        if n.get("columns"):
            s += table(["Columna", "Tipo", "Nullable"],
                       [[c["name"], c.get("type") or "—",
                         "sí" if c.get("nullable") else "no"] for c in n["columns"]])
        else:
            s += "_Columnas no registradas._\n"

        s += "\n- **FK salientes:** %s\n" % (", ".join(
            "`%s` → %s" % (fk["column"], m.label(fk["references"]["node"]))
            for fk in n.get("fks", [])) or "ninguna")
        incoming = ["%s.`%s`" % (m.label(o["id"]), fk["column"])
                    for o in m.nodes for fk in (o.get("fks") or [])
                    if fk["references"]["node"] == n["id"]]
        s += "- **FK entrantes:** %s\n" % (", ".join(incoming) or "ninguna")
        s += "- **Rutinas que la tocan:** %s\n" % (", ".join(routines) or "ninguna")
        s += "- **Lectores:** %s\n" % (", ".join(readers) or "ninguno")
        s += "- **Escritores:** %s%s\n" % (
            ", ".join(writers) or "ninguno",
            "  ⚠ **múltiples**" if len(writers) > 1 else "")
        s += "- **Escenarios:** %s\n\n" % (", ".join(
            link(f, m.flow_path(x), x["title"]) for x in fls) or "ninguno")

    s += "## Preguntas abiertas\n\n"
    s += fill("preguntas-datos", "«Ninguna» si no aplica.") + "\n"
    return f, s


def page_integrations(m):
    f = m.p("integraciones.md")
    s = m.header("Integraciones externas")

    ext = sorted((n for n in m.nodes if n.get("lane") == "external"),
                 key=lambda n: n["id"])
    if not ext:
        s += "_No se detectó ningún sistema externo._\n"
        return f, s

    for n in ext:
        ins = sorted(m.in_edges[n["id"]], key=lambda e: e["from"])
        outs = sorted(m.out_edges[n["id"]], key=lambda e: e["to"])
        fls = m.node_flows.get(n["id"], [])

        s += "## %s\n\n" % cell(n["label"])
        s += "- **id:** `%s` · **kind:** %s\n" % (cell(n["id"]), n.get("kind"))
        if n.get("subtitle"):
            s += "- **subtítulo:** %s\n" % cell(n["subtitle"])
        s += "\n### Lo invoca\n\n"
        s += table(["Componente", "Llamada", "Acceso", "Evidencia"],
                   [[m.ref(f, e["from"]), code(e["call"]), e["access"],
                     "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in ins])
        s += "\n### Invoca a\n\n"
        s += table(["Componente", "Llamada", "Acceso", "Evidencia"],
                   [[m.ref(f, e["to"]), code(e["call"]), e["access"],
                     "`%s`" % cell(e.get("evidence", {}).get("file"))] for e in outs])
        s += "\n### Escenarios implicados\n\n"
        if fls:
            for fl in fls:
                s += "- %s\n" % link(f, m.flow_path(fl), fl["title"])
        else:
            s += "_Ninguno._\n"
        s += "\n"

    s += "## Preguntas abiertas\n\n"
    s += fill("preguntas-integraciones", "«Ninguna» si no aplica.") + "\n"
    return f, s


def page_gaps(m):
    f = m.p("huecos.md")
    s = m.header("Huecos del análisis")

    da = m.stats.get("data_access", {})
    s += "## Cobertura de accesos a datos\n\n"
    s += table(["Métrica", "Valor"], [
        ["Accesos resueltos estáticamente", da.get("resolved", "no calculado")],
        ["Accesos dinámicos o no parseables", da.get("dynamic", "no calculado")],
        ["Porcentaje resuelto",
         "%s%%" % da["pct_resolved"] if da.get("pct_resolved") is not None else "no calculado"],
    ])
    s += "\nUn porcentaje bajo no es un fallo del análisis: significa que el acceso a "
    s += "datos se construye en tiempo de ejecución, y eso es en sí mismo el hallazgo.\n\n"

    if not m.unresolved:
        s += "## Sin resolver\n\n_No se declaró ningún hueco._\n"
        return f, s

    grouped = defaultdict(list)
    for u in m.unresolved:
        grouped[u.get("reason", "sin-motivo")].append(u)

    s += "## Resumen por motivo\n\n"
    s += table(["Motivo", "Casos"],
               [[r, len(v)] for r, v in sorted(grouped.items(),
                                               key=lambda kv: -len(kv[1]))])
    s += "\n"

    for reason, items in sorted(grouped.items(), key=lambda kv: -len(kv[1])):
        s += "## %s — %d caso(s)\n\n" % (reason, len(items))
        s += "**Qué haría falta para resolverlo.** %s\n\n" % REMEDIATION.get(
            reason, "Motivo no reconocido por el generador; documentar a mano.")
        s += table(["Archivo", "Símbolo", "Detalle"],
                   [[code(u.get("file")), code(u.get("symbol")),
                     cell(u.get("detail")) or "—"] for u in items])
        s += "\n"
    return f, s


def page_glossary(m):
    f = m.p("glosario.md")
    s = m.header("Glosario")
    s += "Términos extraídos de los identificadores reales del grafo. La ubicación es "
    s += "un hecho; el significado es inferencia y debe marcarse como tal.\n\n"

    terms = {}
    for n in m.nodes:
        terms.setdefault(n["label"], set()).update(n.get("files") or [])
        if n.get("lane") == "data":
            for c in n.get("columns") or []:
                terms.setdefault(c["name"], set()).add("columna de %s" % n["label"])
    for e in m.edges:
        token = re.sub(r"\(.*\)$", "", str(e["call"])).strip()
        if token:
            terms.setdefault(token, set()).add(e.get("evidence", {}).get("file") or "")

    rows = []
    for term in sorted(terms, key=lambda t: t.lower()):
        where = sorted(x for x in terms[term] if x)
        rows.append([code(term), ", ".join("`%s`" % cell(w) for w in where[:3]) or "—"])
    s += table(["Término", "Dónde aparece"], rows)

    s += "\n## Definiciones\n\n"
    s += fill("glosario",
              "Para los términos de dominio (no los técnicos), una línea de "
              "significado. Solo si está documentado en el código o en comentarios; "
              "si no, escribe «no documentado en el código».") + "\n"
    return f, s


# ----------------------------------------------------------------- driver

def check(root):
    hits = []
    for path in sorted(root.rglob("*.md")):
        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if "[[FILL:" in line:
                hits.append("%s:%d" % (path.relative_to(root), i))
    if hits:
        print("FAIL  %d marcador(es) [[FILL]] sin rellenar:" % len(hits))
        for h in hits[:40]:
            print("      " + h)
        if len(hits) > 40:
            print("      … y %d más" % (len(hits) - 40))
        return 1
    print("OK  ningún marcador [[FILL]] pendiente en %s" % root)
    return 0


def verify_links(root, written):
    """Every relative link emitted must resolve to a file we actually wrote."""
    broken = []
    known = {p.resolve() for p in written}
    for path in written:
        for target in re.findall(r"\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            if target.startswith(("http://", "https://", "#")):
                continue
            resolved = (path.parent / target.split("#")[0]).resolve()
            if resolved not in known:
                broken.append("%s -> %s" % (path.relative_to(root), target))
    return broken


def main(argv):
    argv = argv[1:]
    flags = {a for a in argv if a.startswith("--") and "=" not in a}
    options = dict(a[2:].split("=", 1) for a in argv if a.startswith("--") and "=" in a)
    args = [a for a in argv if not a.startswith("--")]

    root = Path(options.get("out", "docs/archscope"))

    if "--check" in flags:
        if not root.is_dir():
            print("ERROR: no existe %s" % root, file=sys.stderr)
            return 2
        return check(root)

    if len(args) != 1:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    try:
        doc = json.loads(Path(args[0]).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print("ERROR leyendo la entrada: %s" % exc, file=sys.stderr)
        return 2

    if root.exists() and any(root.iterdir()) and "--force" not in flags:
        print("ERROR: %s no está vacío. Usa --force para sobrescribir." % root,
              file=sys.stderr)
        return 1

    m = Model(doc, root)
    pages = [page_readme(m), page_overview(m), page_data_model(m),
             page_integrations(m), page_gaps(m), page_glossary(m)]
    pages += [page_flow(m, fl) for fl in m.flows]
    pages += [page_component(m, n) for n in m.nodes if n.get("lane") != "external"]

    written = []
    for path, body in pages:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")
        written.append(path)

    broken = verify_links(root, written)
    markers = sum(b.count("[[FILL:") for _, b in pages)

    print("Escritos %d ficheros en %s" % (len(written), root))
    print("  escenarios: %d · componentes: %d · marcadores [[FILL]]: %d"
          % (len(m.flows),
             sum(1 for n in m.nodes if n.get("lane") != "external"),
             markers))
    if broken:
        print("FAIL  %d enlace(s) roto(s):" % len(broken))
        for b in broken[:20]:
            print("      " + b)
        return 1
    print("  todos los enlaces relativos resuelven")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
