-- archscope :: SQLite catalog extraction
-- SQLite has no information_schema, no stored procedures and no scheduler.
-- The data graph is therefore thinner by construction, and that is a finding,
-- not a failure: record the absent capabilities in unresolved[] with
-- reason 'engine-exposes-no-logic' so the map does not imply they were missed.

-- === tables() ===================================================
SELECT
    'main.' || m.name                                             AS id,
    'main'                                                        AS schema_name,
    m.name                                                        AS name,
    m.type                                                        AS kind,   -- 'table' | 'view'
    (SELECT group_concat(p.name || ':' || p.type, ',')
       FROM pragma_table_info(m.name) p)                          AS columns
FROM sqlite_master m
WHERE m.type IN ('table', 'view')
  AND m.name NOT LIKE 'sqlite_%'
ORDER BY 1;

-- === routines() =================================================
-- Only triggers and views carry logic. There are no procedures or functions:
-- application-defined functions live in host code, not in the database.
SELECT
    'main.' || name                                               AS id,
    'main'                                                        AS schema_name,
    name                                                          AS name,
    type                                                          AS kind,   -- 'trigger' | 'view'
    sql                                                           AS source
FROM sqlite_master
WHERE type IN ('trigger', 'view')
  AND name NOT LIKE 'sqlite_%'
ORDER BY 1;

-- === deps() =====================================================
-- No dependency catalog. Parse the `sql` column of triggers and views with
-- scripts/classify_sql.py (dialect=sqlite). The trigger's own target table is
-- in sqlite_master.tbl_name and is a write by definition of the trigger event.
SELECT
    'main.' || name                                               AS from_id,
    'main.' || tbl_name                                           AS to_id,
    'trigger-on'                                                  AS dep_type,
    sql                                                           AS definition_to_parse
FROM sqlite_master
WHERE type = 'trigger'
ORDER BY 1;

-- === constraints() ==============================================
-- Per table; iterate over the tables() result. Returns one row per FK column.
--   SELECT * FROM pragma_foreign_key_list('<table>');
-- Reshape as: { from: 'main.<table>', to: 'main.' || "table", type: 'fk' }
SELECT
    'main.' || m.name                                             AS from_id,
    'main.' || f."table"                                          AS to_id,
    'fk'                                                          AS dep_type,
    f."from"                                                      AS from_column,
    f."to"                                                        AS to_column
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name NOT LIKE 'sqlite_%'
ORDER BY 1, 2;

-- === jobs() =====================================================
-- SQLite has no scheduler. Any recurring work is driven from application code
-- or the host OS. Look for it in Phase 1A (cron entries, systemd timers, k8s
-- CronJob, node-cron, APScheduler, Quartz) and emit an unresolved[] entry with
-- reason 'engine-exposes-no-logic' if a scheduler is referenced but not found.
SELECT 'sqlite-has-no-scheduler' AS note;
