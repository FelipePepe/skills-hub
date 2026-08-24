-- archscope :: MySQL / MariaDB catalog extraction
-- Implements the DataExtractor contract. ROUTINE_DEFINITION holds the body
-- only. MySQL exposes no routine->table dependency catalog at all, so deps()
-- comes entirely from parsing bodies with scripts/classify_sql.py.
-- Replace :db with the application schema in every section.

-- === tables() ===================================================
SELECT
    CONCAT(c.TABLE_SCHEMA, '.', c.TABLE_NAME)                     AS id,
    c.TABLE_SCHEMA                                                AS `schema`,
    c.TABLE_NAME                                                  AS name,
    IF(t.TABLE_TYPE = 'VIEW', 'view', 'table')                    AS kind,
    JSON_ARRAYAGG(JSON_OBJECT(
        'name', c.COLUMN_NAME,
        'type', c.DATA_TYPE,
        'nullable', c.IS_NULLABLE = 'YES'
    ))                                                            AS columns
FROM information_schema.COLUMNS c
JOIN information_schema.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = :db
GROUP BY c.TABLE_SCHEMA, c.TABLE_NAME, t.TABLE_TYPE
ORDER BY 1;

-- === routines() =================================================
SELECT
    CONCAT(ROUTINE_SCHEMA, '.', ROUTINE_NAME)                     AS id,
    ROUTINE_SCHEMA                                                AS `schema`,
    ROUTINE_NAME                                                  AS name,
    LOWER(ROUTINE_TYPE)                                           AS kind,
    ROUTINE_DEFINITION                                            AS source
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = :db
ORDER BY 1;

-- Triggers are routines too, and they are invisible from application code.
SELECT
    CONCAT(TRIGGER_SCHEMA, '.', TRIGGER_NAME)                     AS id,
    TRIGGER_SCHEMA                                                AS `schema`,
    TRIGGER_NAME                                                  AS name,
    'trigger'                                                     AS kind,
    ACTION_STATEMENT                                              AS source,
    CONCAT(EVENT_OBJECT_SCHEMA, '.', EVENT_OBJECT_TABLE)          AS on_table,
    EVENT_MANIPULATION                                            AS on_event
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = :db
ORDER BY 1;

-- === deps() =====================================================
-- No catalog source exists. Parse routines()/triggers() bodies instead.
-- View -> base table is the one deterministic edge available:
SELECT
    CONCAT(VIEW_SCHEMA, '.', TABLE_NAME)                          AS `from`,
    VIEW_DEFINITION                                               AS definition_to_parse,
    'read'                                                        AS type
FROM information_schema.VIEWS
WHERE VIEW_SCHEMA = :db
ORDER BY 1;

-- === constraints() ==============================================
SELECT
    CONCAT(k.TABLE_SCHEMA, '.', k.TABLE_NAME)                     AS `from`,
    CONCAT(k.REFERENCED_TABLE_SCHEMA, '.', k.REFERENCED_TABLE_NAME) AS `to`,
    'fk'                                                          AS type,
    k.CONSTRAINT_NAME                                             AS name
FROM information_schema.KEY_COLUMN_USAGE k
WHERE k.REFERENCED_TABLE_NAME IS NOT NULL
  AND k.TABLE_SCHEMA = :db
ORDER BY 1, 2;

-- === jobs() =====================================================
-- Requires event_scheduler = ON; a disabled scheduler still lists its events.
SELECT
    CONCAT(EVENT_SCHEMA, '.', EVENT_NAME)                         AS id,
    COALESCE(
        CONCAT('EVERY ', INTERVAL_VALUE, ' ', INTERVAL_FIELD),
        EXECUTE_AT
    )                                                             AS schedule,
    EVENT_DEFINITION                                              AS command,
    STATUS                                                        AS status
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = :db
ORDER BY 1;

-- Confirm the scheduler actually runs; a disabled one means the job exists but
-- never fires — record that in the node subtitle, do not drop the node.
SHOW VARIABLES LIKE 'event_scheduler';
