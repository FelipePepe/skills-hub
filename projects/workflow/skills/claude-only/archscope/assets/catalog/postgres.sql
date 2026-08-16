-- archscope :: PostgreSQL catalog extraction
-- Implements the DataExtractor contract. Run each section separately and feed
-- the ROUTINES output into scripts/classify_sql.py: pg_depend records that a
-- routine touches a table, never whether it reads or writes it.
-- Adjust the schema filter in every section if the app is not in 'public'.

-- === tables() -> [{ id, schema, name, columns[] }] ===============
-- kind: 'table' | 'view'
SELECT
    c.table_schema || '.' || c.table_name            AS id,
    c.table_schema                                   AS schema,
    c.table_name                                     AS name,
    CASE t.table_type WHEN 'VIEW' THEN 'view' ELSE 'table' END AS kind,
    json_agg(json_build_object(
        'name', c.column_name,
        'type', c.data_type,
        'nullable', c.is_nullable = 'YES'
    ) ORDER BY c.ordinal_position)                    AS columns
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY c.table_schema, c.table_name, t.table_type
ORDER BY 1;

-- === routines() -> [{ id, schema, name, kind, source }] ==========
-- prosrc holds the body only (no CREATE wrapper) for SQL/PLpgSQL routines.
SELECT
    n.nspname || '.' || p.proname                     AS id,
    n.nspname                                         AS schema,
    p.proname                                         AS name,
    CASE p.prokind
        WHEN 'p' THEN 'procedure'
        WHEN 'a' THEN 'aggregate'
        WHEN 'w' THEN 'window'
        ELSE 'function'
    END                                               AS kind,
    l.lanname                                         AS language,
    p.prosrc                                          AS source
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
JOIN pg_language  l ON l.oid = p.prolang
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND l.lanname NOT IN ('c', 'internal')
ORDER BY 1;

-- === deps() -> [{ from, to, type }] =============================
-- Untyped adjacency only. type MUST be recovered by parsing `source` above.
-- Emit these as candidates; classify_sql.py produces the authoritative typed set.
SELECT DISTINCT
    sn.nspname || '.' || sp.proname                   AS "from",
    dn.nspname || '.' || dc.relname                   AS "to",
    'unclassified'                                    AS type
FROM pg_depend d
JOIN pg_proc      sp ON sp.oid = d.objid
JOIN pg_namespace sn ON sn.oid = sp.pronamespace
JOIN pg_class     dc ON dc.oid = d.refobjid
JOIN pg_namespace dn ON dn.oid = dc.relnamespace
WHERE d.classid = 'pg_proc'::regclass
  AND d.refclassid = 'pg_class'::regclass
  AND dc.relkind IN ('r', 'v', 'm', 'p')
  AND dn.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

-- View -> base table dependencies (deterministic, no parsing needed).
SELECT DISTINCT
    dependent_ns.nspname || '.' || dependent_view.relname AS "from",
    source_ns.nspname || '.' || source_table.relname      AS "to",
    'read'                                                AS type
FROM pg_depend d
JOIN pg_rewrite   r  ON r.oid = d.objid
JOIN pg_class     dependent_view ON dependent_view.oid = r.ev_class
JOIN pg_class     source_table   ON source_table.oid = d.refobjid
JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
JOIN pg_namespace source_ns    ON source_ns.oid = source_table.relnamespace
WHERE d.classid = 'pg_rewrite'::regclass
  AND dependent_view.oid <> source_table.oid
  AND source_ns.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

-- === constraints() -> [{ from, to, type: fk }] ==================
SELECT
    tc.table_schema || '.' || tc.table_name           AS "from",
    ccu.table_schema || '.' || ccu.table_name         AS "to",
    'fk'                                              AS type,
    tc.constraint_name                                AS name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name
 AND kcu.table_schema = tc.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

-- === jobs() -> [{ id, schedule, calls[] }] ======================
-- Scheduled jobs are first-class entrypoints: they hang off no request and are
-- usually the undocumented flows. Absent extension != absent scheduler; if both
-- queries error, check for an external scheduler (cron, Airflow, k8s CronJob)
-- and record the gap in unresolved[].

-- pg_cron
SELECT
    'cron.job.' || j.jobid                            AS id,
    j.schedule                                        AS schedule,
    j.command                                         AS command,
    j.jobname                                         AS name
FROM cron.job j
ORDER BY 1;

-- pgAgent
SELECT
    'pgagent.' || jb.jobid                            AS id,
    sc.jscstart::text                                 AS schedule,
    st.jstcode                                        AS command,
    jb.jobname                                        AS name
FROM pgagent.pga_job jb
LEFT JOIN pgagent.pga_schedule sc ON sc.jscjobid = jb.jobid
LEFT JOIN pgagent.pga_jobstep  st ON st.jstjobid = jb.jobid
ORDER BY 1;
