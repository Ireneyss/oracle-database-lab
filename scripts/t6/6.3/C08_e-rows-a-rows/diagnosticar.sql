-- C08 · diagnosticar · el plan real línea a línea: dónde empieza la mala estimación (E-Rows × Starts frente a A-Rows)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF LINESIZE 170
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_antes%' AND ROWNUM = 1),
  NULL, 'ALLSTATS LAST +PREDICATE -NOTE'));
PROMPT -- Lectura: lee de dentro afuera. La PRIMERA línea donde E-Rows (× Starts) se aleja de A-Rows es la del filtro
PROMPT -- ciudad + comunidad sobre CLIENTE. Todo lo que está encima hereda el error (pedidos estimados frente a reales).
EXIT
