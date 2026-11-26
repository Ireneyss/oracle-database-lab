-- C11 · diagnosticar · lo que pasó: STATISTICS COLLECTOR contó las filas de verdad y decidió a mitad de ejecución
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%' AND ROWNUM = 1), NULL, 'IOSTATS LAST +ADAPTIVE'));
SET ECHO OFF
PROMPT -- Lectura: las líneas marcadas con «-» son el camino descartado. Las que tienen Starts > 0 son las que se ejecutaron.
EXIT
