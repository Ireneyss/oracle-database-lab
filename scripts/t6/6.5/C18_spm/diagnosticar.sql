-- C18 · diagnosticar · ¿qué cambió? El plan de hoy, el del lunes (en AWR) y la historia de las estadísticas
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 160 SERVEROUTPUT OFF
PROMPT == El plan de hoy (cursor en memoria) ==
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND ROWNUM = 1),
  (SELECT MAX(child_number) FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND is_shareable = 'Y'), 'BASIC +ROWS +COST'));
PROMPT == Los planes que AWR conoce de este SQL (el del lunes sigue ahí) ==
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(
  sql_id => (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND ROWNUM = 1),
  format => 'BASIC +ROWS +COST', awr_location => 'AWR_PDB'));
PROMPT == Lo que cambió: el histograma de ESTADO ha desaparecido en la recogida nocturna ==
COLUMN column_name FORMAT A12
SELECT column_name, num_distinct, histogram, TO_CHAR(last_analyzed, 'HH24:MI:SS') AS analizada
  FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO';
SELECT TO_CHAR(stats_update_time, 'YYYY-MM-DD HH24:MI:SS') AS recogidas FROM dba_tab_stats_history
 WHERE owner = 'T6' AND table_name = 'PEDIDO' ORDER BY stats_update_time DESC FETCH FIRST 3 ROWS ONLY;
PROMPT -- Lectura: sin histograma, ESTADO = 'P' se estima en 1/4 de la tabla (250 000) y el optimizador prefiere
PROMPT -- recorrerla entera. Con histograma sabe que son 20 000 y usa el índice. Arreglar las estadísticas es una
PROMPT -- solución (C13); SPM es la otra: que el plan probado no se pierda aunque el entorno vuelva a cambiar.
EXIT
