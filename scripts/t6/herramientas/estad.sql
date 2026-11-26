-- =====================================================================================================
-- herramientas/estad.sql · la imagen del mundo que tiene el optimizador de una tabla (runbook RB-2)
-- Uso: t6 estad TABLA [esquema]        esquema por defecto: T6
-- Muestra: (1) filas, bloques, fecha, ¿obsoletas?, ¿bloqueadas?; (2) cambios desde la última recogida;
--   (3) columnas: distintos, nulos, histograma; (4) extensiones (grupos de columnas); (5) estadísticas pendientes;
--   (6) historial (lo que DBMS_STATS.RESTORE_TABLE_STATS puede devolver) y (7) preferencias de la tabla.
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO
COLUMN stattype_locked FORMAT A6 HEADING LOCKED
COLUMN column_name FORMAT A30
COLUMN density FORMAT 0.000000
PROMPT == 1 · Estadísticas de la tabla &2..&1 ==
SELECT table_name, num_rows, blocks, avg_row_len, last_analyzed, stale_stats, stattype_locked
  FROM dba_tab_statistics WHERE owner = UPPER('&2') AND table_name = UPPER('&1') AND object_type = 'TABLE';
PROMPT == 2 · Cambios desde la última recogida (DBA_TAB_MODIFICATIONS; obsoleta si pasan del 10 %) ==
SELECT m.inserts, m.updates, m.deletes, m.truncated, ROUND(100 * (m.inserts + m.updates + m.deletes) / NULLIF(t.num_rows, 0), 1) AS pct_cambio
  FROM dba_tab_modifications m JOIN dba_tables t ON t.owner = m.table_owner AND t.table_name = m.table_name
 WHERE m.table_owner = UPPER('&2') AND m.table_name = UPPER('&1') AND m.partition_name IS NULL;
PROMPT == 3 · Columnas: lo que sabe el optimizador de cada una ==
SELECT column_name, num_distinct, num_nulls, ROUND(density, 6) AS density, num_buckets AS buckets, histogram, last_analyzed
  FROM dba_tab_col_statistics WHERE owner = UPPER('&2') AND table_name = UPPER('&1') ORDER BY column_name;
PROMPT == 4 · Extensiones (grupos de columnas y expresiones) ==
SELECT extension_name, extension, creator FROM dba_stat_extensions WHERE owner = UPPER('&2') AND table_name = UPPER('&1');
PROMPT == 5 · Estadísticas PENDIENTES (recogidas con PUBLISH = FALSE, aún sin publicar) ==
SELECT table_name, num_rows, blocks, last_analyzed FROM dba_tab_pending_stats
 WHERE owner = UPPER('&2') AND table_name = UPPER('&1') AND partition_name IS NULL;
PROMPT == 6 · Historial: versiones anteriores que se pueden restaurar ==
SELECT TO_CHAR(stats_update_time, 'YYYY-MM-DD HH24:MI:SS') AS cuando FROM dba_tab_stats_history
 WHERE owner = UPPER('&2') AND table_name = UPPER('&1') ORDER BY stats_update_time DESC FETCH FIRST 5 ROWS ONLY;
PROMPT == 7 · Preferencias que usará la próxima recogida ==
SELECT 'PUBLISH' AS preferencia, DBMS_STATS.GET_PREFS('PUBLISH', UPPER('&2'), UPPER('&1')) AS valor FROM dual
UNION ALL SELECT 'METHOD_OPT', DBMS_STATS.GET_PREFS('METHOD_OPT', UPPER('&2'), UPPER('&1')) FROM dual
UNION ALL SELECT 'STALE_PERCENT', DBMS_STATS.GET_PREFS('STALE_PERCENT', UPPER('&2'), UPPER('&1')) FROM dual;
EXIT
