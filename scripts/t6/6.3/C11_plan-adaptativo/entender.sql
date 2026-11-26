-- C11 · entender · el plan «que se predijo»: tiene DOS métodos de join a la vez (y uno quedará inactivo)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%' AND ROWNUM = 1), NULL, 'BASIC +ADAPTIVE +ROWS'));
EXIT
