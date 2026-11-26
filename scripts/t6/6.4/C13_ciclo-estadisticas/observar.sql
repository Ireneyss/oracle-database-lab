-- C13 · observar · la red de seguridad: volver atrás (RESTORE) y bloquear (LOCK, con su error esperado ORA-20005).
-- Al final devuelve PEDIDO a su estado (deshace el UPDATE y recoge sin histograma). Errores esperados: ORA-20005
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
COLUMN cuando FORMAT A19
PROMPT == 1 · El historial: cada recogida guarda la anterior (retención en días) ==
SELECT TO_CHAR(stats_update_time, 'YYYY-MM-DD HH24:MI:SS') AS cuando FROM dba_tab_stats_history
 WHERE owner = 'T6' AND table_name = 'PEDIDO' ORDER BY stats_update_time DESC FETCH FIRST 3 ROWS ONLY;
SELECT DBMS_STATS.GET_STATS_HISTORY_RETENTION AS dias_de_retencion FROM dual;
PROMPT == 2 · Si la publicación hubiera empeorado algo: restaurar las de hace 1 minuto (sin histograma) ==
EXEC DBMS_STATS.RESTORE_TABLE_STATS('T6', 'PEDIDO', SYSTIMESTAMP - INTERVAL '60' SECOND, no_invalidate => FALSE)
SELECT column_name, histogram FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO';
PROMPT == 3 · Bloquear: una recogida posterior falla A PROPÓSITO con ORA-20005 (así se protege una tabla de trabajo) ==
EXEC DBMS_STATS.LOCK_TABLE_STATS('T6', 'PEDIDO')
SELECT stattype_locked FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO';
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO')
EXEC DBMS_STATS.UNLOCK_TABLE_STATS('T6', 'PEDIDO')
PROMPT == 4 · Se devuelve PEDIDO a su estado inicial (para los demás casos) ==
UPDATE t6.pedido SET estado = 'C' WHERE id_pedido IN (SELECT id_pedido FROM t6.c13_cambio);
COMMIT;
DROP TABLE t6.c13_cambio PURGE;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR ALL COLUMNS SIZE 1', no_invalidate => FALSE)
SET ECHO OFF
PROMPT == Lo que debes retener ==
PROMPT 1. Las estadísticas son configuración: se cambian con red (PUBLISH = FALSE, pendientes, prueba en sesión, publicar).
PROMPT 2. Siempre hay vuelta atrás: DBMS_STATS.RESTORE_TABLE_STATS a un instante (DBA_TAB_STATS_HISTORY).
PROMPT 3. LOCK_TABLE_STATS protege una tabla de trabajo de la tarea automática; ORA-20005 avisa a quien intente recoger.
PROMPT    Se recoge igualmente con force => TRUE (decisión consciente, no un truco).
EXIT
