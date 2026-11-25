-- C11 · solucionar · no hay nada que arreglar: se comprueba que el plan quedó RESUELTO y cuál es el plan final
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
SELECT sql_id, child_number, is_resolved_adaptive_plan AS resuelto, plan_hash_value
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%' AND ROWNUM = 1), NULL, 'BASIC +ROWS'));
EXIT
