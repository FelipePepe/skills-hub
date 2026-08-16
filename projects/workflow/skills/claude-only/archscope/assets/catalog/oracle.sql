-- archscope :: Oracle catalog extraction
-- Implements the DataExtractor contract. ALL_SOURCE returns the body one line
-- per row: reassemble with LISTAGG (or fetch ordered and join client-side)
-- before handing it to scripts/classify_sql.py with dialect=oracle.
-- Swap ALL_* for DBA_* when the connection has the privilege; ALL_* only shows
-- objects the current user can see, which silently shrinks the graph.

-- === tables() ===================================================
SELECT
    c.OWNER || '.' || c.TABLE_NAME                                AS id,
    c.OWNER                                                       AS schema_name,
    c.TABLE_NAME                                                  AS name,
    CASE WHEN v.VIEW_NAME IS NULL THEN 'table' ELSE 'view' END    AS kind,
    LISTAGG(c.COLUMN_NAME || ':' || c.DATA_TYPE, ',')
        WITHIN GROUP (ORDER BY c.COLUMN_ID)                       AS columns
FROM ALL_TAB_COLUMNS c
LEFT JOIN ALL_VIEWS v ON v.OWNER = c.OWNER AND v.VIEW_NAME = c.TABLE_NAME
WHERE c.OWNER NOT IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN')
GROUP BY c.OWNER, c.TABLE_NAME, v.VIEW_NAME
ORDER BY 1;

-- === routines() =================================================
-- One row per routine, body reassembled.
SELECT
    s.OWNER || '.' || s.NAME                                      AS id,
    s.OWNER                                                       AS schema_name,
    s.NAME                                                        AS name,
    LOWER(s.TYPE)                                                 AS kind,
    LISTAGG(s.TEXT, '') WITHIN GROUP (ORDER BY s.LINE)            AS source
FROM ALL_SOURCE s
WHERE s.TYPE IN ('PROCEDURE', 'FUNCTION', 'PACKAGE BODY', 'TRIGGER')
  AND s.OWNER NOT IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN')
GROUP BY s.OWNER, s.NAME, s.TYPE
ORDER BY 1;

-- If a body exceeds the LISTAGG 4000-byte limit, fetch it line by line instead
-- and join in the client. Never truncate: a truncated body parses into a wrong
-- access set, which is worse than an unresolved entry.
--   SELECT OWNER, NAME, TYPE, LINE, TEXT FROM ALL_SOURCE
--    WHERE OWNER = :owner AND NAME = :name ORDER BY LINE;

-- === deps() =====================================================
-- Untyped adjacency; classification comes from parsing the body.
SELECT
    d.OWNER || '.' || d.NAME                                      AS from_id,
    d.REFERENCED_OWNER || '.' || d.REFERENCED_NAME                AS to_id,
    'unclassified'                                                AS dep_type,
    d.TYPE                                                        AS from_type,
    d.REFERENCED_TYPE                                             AS to_type
FROM ALL_DEPENDENCIES d
WHERE d.REFERENCED_TYPE IN ('TABLE', 'VIEW', 'PROCEDURE', 'FUNCTION', 'PACKAGE')
  AND d.OWNER NOT IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN')
  AND d.REFERENCED_OWNER NOT IN ('SYS', 'SYSTEM', 'XDB', 'PUBLIC')
ORDER BY 1, 2;

-- === constraints() ==============================================
SELECT
    ac.OWNER || '.' || ac.TABLE_NAME                              AS from_id,
    rc.OWNER || '.' || rc.TABLE_NAME                              AS to_id,
    'fk'                                                          AS dep_type,
    ac.CONSTRAINT_NAME                                            AS name
FROM ALL_CONSTRAINTS ac
JOIN ALL_CONSTRAINTS rc
  ON rc.CONSTRAINT_NAME = ac.R_CONSTRAINT_NAME
 AND rc.OWNER = ac.R_OWNER
WHERE ac.CONSTRAINT_TYPE = 'R'
  AND ac.OWNER NOT IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'OUTLN')
ORDER BY 1, 2;

-- === jobs() =====================================================
-- DBMS_SCHEDULER. JOB_ACTION is the code to parse for `calls[]`.
SELECT
    j.OWNER || '.' || j.JOB_NAME                                  AS id,
    NVL(j.REPEAT_INTERVAL, j.START_DATE)                          AS schedule,
    j.JOB_ACTION                                                  AS command,
    j.JOB_TYPE                                                    AS job_type,
    j.ENABLED                                                     AS enabled,
    j.STATE                                                       AS state
FROM ALL_SCHEDULER_JOBS j
WHERE j.OWNER NOT IN ('SYS', 'SYSTEM')
ORDER BY 1;

-- Legacy DBMS_JOB — still present in older schemas, easily missed.
SELECT
    'dbms_job.' || TO_CHAR(JOB)                                   AS id,
    INTERVAL                                                      AS schedule,
    WHAT                                                          AS command,
    BROKEN                                                        AS broken
FROM ALL_JOBS
ORDER BY 1;
