-- C16 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Existe el índice basado en función IX_T6_CLI_EMAIL_UP' AS resultado
  FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_CLI_EMAIL_UP' AND index_type LIKE 'FUNCTION-BASED%'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'La búsqueda de la web usa el índice nuevo'
  FROM v$sql_plan WHERE object_name = 'IX_T6_CLI_EMAIL_UP'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login_v2 */%')
UNION ALL
SELECT CASE WHEN d.g * 20 < a.g THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas lógicas por búsqueda: ' || d.g || ' frente a ' || a.g
  FROM (SELECT MAX(ROUND(buffer_gets / executions)) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login_v2 */%') d,
       (SELECT MAX(ROUND(buffer_gets / executions)) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login */%') a;
EXIT
