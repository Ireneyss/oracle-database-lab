-- C05 · diagnosticar · el plan real: cuántas veces se ejecuta cada línea (Starts) en los bucles anidados
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF LINESIZE 170
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c p) USE_NL%t6_c05_nl%' AND ROWNUM = 1),
  NULL, 'ALLSTATS LAST -NOTE'));
PROMPT -- Lectura: la parte interna del NESTED LOOPS se repite UNA VEZ POR CLIENTE de España (Starts ≈ 60 000).
PROMPT -- Bucles anidados = pocas filas de entrada. Con el 60 % de los clientes, el método correcto es HASH JOIN.
EXIT
