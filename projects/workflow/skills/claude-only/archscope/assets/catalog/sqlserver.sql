-- archscope :: SQL Server catalog extraction
-- Implements the DataExtractor contract. sys.sql_modules.definition returns the
-- FULL CREATE statement, so classify_sql.py unwraps it before walking the AST.
-- sys.sql_expression_dependencies does expose is_selected/is_updated, but it is
-- unreliable for dynamic SQL and cross-database refs — treat it as a candidate
-- set and let the parser produce the authoritative classification.

-- === tables() ===================================================
SELECT
    s.name + '.' + t.name                                         AS id,
    s.name                                                        AS [schema],
    t.name                                                        AS name,
    'table'                                                       AS kind,
    (SELECT c.name AS [name], ty.name AS [type], c.is_nullable AS [nullable]
       FROM sys.columns c
       JOIN sys.types ty ON ty.user_type_id = c.user_type_id
      WHERE c.object_id = t.object_id
      ORDER BY c.column_id
      FOR JSON PATH)                                              AS columns
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
UNION ALL
SELECT
    s.name + '.' + v.name, s.name, v.name, 'view',
    (SELECT c.name AS [name], ty.name AS [type], c.is_nullable AS [nullable]
       FROM sys.columns c
       JOIN sys.types ty ON ty.user_type_id = c.user_type_id
      WHERE c.object_id = v.object_id
      ORDER BY c.column_id
      FOR JSON PATH)
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
ORDER BY 1;

-- === routines() =================================================
SELECT
    s.name + '.' + o.name                                         AS id,
    s.name                                                        AS [schema],
    o.name                                                        AS name,
    LOWER(CASE o.type
        WHEN 'P'  THEN 'procedure'
        WHEN 'FN' THEN 'function'
        WHEN 'IF' THEN 'function'
        WHEN 'TF' THEN 'function'
        WHEN 'TR' THEN 'trigger'
        WHEN 'V'  THEN 'view'
    END)                                                          AS kind,
    m.definition                                                  AS source
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY 1;

-- === deps() =====================================================
-- Candidate adjacency. is_selected/is_updated are hints, not the contract:
-- confirm every row against the parsed body.
SELECT DISTINCT
    s.name + '.' + o.name                                         AS [from],
    COALESCE(d.referenced_schema_name, 'dbo') + '.' + d.referenced_entity_name AS [to],
    CASE
        WHEN d.is_updated = 1 THEN 'write'
        WHEN d.is_selected = 1 THEN 'read'
        ELSE 'unclassified'
    END                                                           AS type
FROM sys.sql_expression_dependencies d
JOIN sys.objects o ON o.object_id = d.referencing_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE d.referenced_id IS NOT NULL
ORDER BY 1, 2;

-- === constraints() ==============================================
SELECT
    ps.name + '.' + pt.name                                       AS [from],
    rs.name + '.' + rt.name                                       AS [to],
    'fk'                                                          AS type,
    fk.name                                                       AS name
FROM sys.foreign_keys fk
JOIN sys.tables  pt ON pt.object_id = fk.parent_object_id
JOIN sys.schemas ps ON ps.schema_id = pt.schema_id
JOIN sys.tables  rt ON rt.object_id = fk.referenced_object_id
JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
ORDER BY 1, 2;

-- === jobs() =====================================================
-- SQL Agent jobs live in msdb and need permissions there. A job whose step
-- calls a procedure is an entrypoint node with a `call` edge into that routine.
SELECT
    'agent.' + CAST(j.job_id AS VARCHAR(64))                      AS id,
    j.name                                                        AS name,
    j.enabled                                                     AS enabled,
    sch.name                                                      AS schedule_name,
    sch.freq_type                                                 AS freq_type,
    sch.active_start_time                                         AS start_time,
    st.step_name                                                  AS step_name,
    st.database_name                                              AS target_db,
    st.command                                                    AS command
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js ON js.job_id = j.job_id
LEFT JOIN msdb.dbo.sysschedules sch   ON sch.schedule_id = js.schedule_id
LEFT JOIN msdb.dbo.sysjobsteps st     ON st.job_id = j.job_id
ORDER BY 1, st.step_id;
