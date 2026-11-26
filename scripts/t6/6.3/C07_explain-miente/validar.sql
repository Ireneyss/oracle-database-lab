-- C07 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'V2 usa el índice IX_T6_PED_CP (INDEX RANGE SCAN)' AS resultado
  FROM v$sql_plan WHERE object_name = 'IX_T6_PED_CP' AND operation = 'INDEX'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%')
UNION ALL
SELECT CASE WHEN v2.g * 10 < v1.g THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas por búsqueda: ' || ROUND(v2.g) || ' frente a ' || ROUND(v1.g)
  FROM (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%') v2,
       (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%') v1
UNION ALL
SELECT CASE WHEN v2.p95 * 5 < v1.p95 THEN 'OK    ' ELSE 'FALLO ' END || 'Latencia p95 de la web: ' || ROUND(v2.p95, 1) || ' ms frente a ' || ROUND(v1.p95, 1) || ' ms'
  FROM (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms) p95 FROM t6.app_log WHERE etq = 'C07_V2') v2,
       (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms) p95 FROM t6.app_log WHERE etq = 'C07_V1') v1;
EXIT
