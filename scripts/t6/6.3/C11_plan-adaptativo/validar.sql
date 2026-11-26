-- C11 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN MAX(is_resolved_adaptive_plan) = 'Y' THEN 'OK    ' ELSE 'FALLO ' END || 'El plan adaptativo quedó resuelto en la primera ejecución' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Parámetro optimizer_adaptive_plans = ' || MAX(value)
  FROM v$parameter WHERE name = 'optimizer_adaptive_plans' AND value = 'TRUE';
EXIT
