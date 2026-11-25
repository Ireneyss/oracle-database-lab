-- C12 · diagnosticar · dos pruebas: el plan real (E-Rows frente a A-Rows) y el estado de las estadísticas (t6 estad)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF LINESIZE 170
PROMPT == 1 · El plan real del informe ==
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_antes%' AND ROWNUM = 1), NULL, 'ALLSTATS LAST -NOTE'));
PROMPT == 2 · ¿Están obsoletas? Cambios desde la última recogida y la marca STALE ==
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO
SELECT inserts, updates, deletes FROM dba_tab_modifications WHERE table_owner = 'T6' AND table_name = 'CARRITO';
SELECT num_rows, last_analyzed, stale_stats, stattype_locked FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'CARRITO';
PROMPT -- Lectura: E-Rows 100 en CARRITO y A-Rows 200 100. Con 100 filas, bucles anidados por la PK de PEDIDO es lo
PROMPT -- lógico; con 200 100, son 200 100 visitas al índice y a la tabla. STALE = YES: la causa está confirmada.
EXIT
