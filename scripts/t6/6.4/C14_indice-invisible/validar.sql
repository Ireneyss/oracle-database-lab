-- C14 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'El índice IX_T6_C14_PEND existe, VISIBLE y VALID' AS resultado
  FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_C14_PEND' AND visibility = 'VISIBLE' AND status = 'VALID'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El panel publicado usa el índice nuevo'
  FROM v$sql_plan WHERE object_name = 'IX_T6_C14_PEND'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel_v2 */%')
UNION ALL
SELECT CASE WHEN d.g * 10 < a.g THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas lógicas por apertura: ' || d.g || ' frente a ' || a.g
  FROM (SELECT MAX(ROUND(buffer_gets / executions)) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel_v2 */%') d,
       (SELECT MAX(ROUND(buffer_gets / executions)) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel */%') a;
EXIT
