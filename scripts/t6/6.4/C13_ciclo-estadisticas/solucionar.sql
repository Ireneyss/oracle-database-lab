-- C13 · solucionar · runbook RB-2: recoger SIN publicar, probar en UNA sesión, publicar y volver a la preferencia normal
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
COLUMN tipo FORMAT A10
PROMPT == 1 · Recoger como PENDIENTES (PUBLISH = FALSE): nadie las usa todavía ==
EXEC DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO', 'PUBLISH', 'FALSE')
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS estado SIZE 254')
SELECT 'publicadas' AS tipo, num_rows, last_analyzed FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO'
UNION ALL
SELECT 'pendientes', num_rows, last_analyzed FROM dba_tab_pending_stats WHERE owner = 'T6' AND table_name = 'PEDIDO' AND partition_name IS NULL;
PROMPT == 2 · Probarlas SOLO en esta sesión ==
DELETE FROM plan_table;
ALTER SESSION SET optimizer_use_pending_statistics = TRUE;
EXPLAIN PLAN FOR SELECT * FROM t6.pedido WHERE estado = 'E';
SELECT cardinality AS estimadas_con_pendientes FROM plan_table WHERE id = 1;
ALTER SESSION SET optimizer_use_pending_statistics = FALSE;
ROLLBACK;
PROMPT == 3 · La prueba es buena: publicar, y la preferencia vuelve a TRUE ==
EXEC DBMS_STATS.PUBLISH_PENDING_STATS('T6', 'PEDIDO')
EXEC DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO', 'PUBLISH', 'TRUE')
SELECT num_rows, last_analyzed, stale_stats FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO';
EXIT
