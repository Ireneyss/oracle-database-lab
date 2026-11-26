-- C13 · diagnosticar · el estado de las estadísticas de PEDIDO (es lo que muestra «t6 estad PEDIDO»)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO
SELECT num_rows, last_analyzed, stale_stats, stattype_locked FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO';
SELECT inserts, updates, deletes FROM dba_tab_modifications WHERE table_owner = 'T6' AND table_name = 'PEDIDO' AND partition_name IS NULL;
SELECT column_name, num_distinct, histogram FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO';
SELECT 'PUBLISH' AS preference_name, DBMS_STATS.GET_PREFS('PUBLISH', 'T6', 'PEDIDO') AS preference_value FROM dual;
PROMPT -- Lectura: STALE = YES y ESTADO sin histograma. Recoger ya es correcto... pero publicar a ciegas en hora punta
PROMPT -- cambia los planes de TODA la aplicación a la vez. El runbook RB-2: pendientes → probar → publicar (→ restaurar).
EXIT
