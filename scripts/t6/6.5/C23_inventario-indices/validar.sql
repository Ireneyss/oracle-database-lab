-- C23 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'No hay un índice nuevo duplicado: un solo índice empieza por (ID_CLIENTE, FECHA_PEDIDO)' AS resultado
  FROM (SELECT index_name FROM dba_ind_columns WHERE index_owner = 'T6' AND table_name = 'PEDIDO'
         GROUP BY index_name HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position) LIKE 'ID_CLIENTE,FECHA_PEDIDO%')
UNION ALL
SELECT CASE WHEN visibility = 'INVISIBLE' THEN 'OK    ' ELSE 'FALLO ' END || 'IX_T6_PED_CLIENTE retirado con red: ' || visibility || ' (no borrado)'
  FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_PED_CLIENTE'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El historial del cliente usa IX_C23_CLI_FECHA'
  FROM v$sql_plan WHERE object_name = 'IX_C23_CLI_FECHA'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c23_historial */%');
EXIT
