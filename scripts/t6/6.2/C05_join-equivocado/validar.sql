-- C05 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El informe sin sugerencia usa HASH JOIN' AS resultado
  FROM v$sql_plan WHERE operation = 'HASH JOIN'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c05_ok%')
UNION ALL
SELECT CASE WHEN ok.g * 5 < nl.g THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas lógicas: ' || ok.g || ' frente a ' || nl.g || ' con la sugerencia'
  FROM (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c05_ok%') ok,
       (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c p) USE_NL%t6_c05_nl%') nl;
EXIT
