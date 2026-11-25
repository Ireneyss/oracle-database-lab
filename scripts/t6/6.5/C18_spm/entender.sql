-- C18 · entender · el mismo SQL, dos planes: lo que ha visto cada día el informe de pendientes
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN dia FORMAT A8
SELECT CASE WHEN q.snap_id <= s.fin THEN 'LUNES' END AS dia, q.sql_id, q.plan_hash_value,
       SUM(q.executions_delta) AS ejec, ROUND(SUM(q.buffer_gets_delta) / NULLIF(SUM(q.executions_delta), 0)) AS gets_ejec
  FROM awr_pdb_sqlstat q, (SELECT MAX(DECODE(etq, 'LUNES_INI', snap_id)) ini, MAX(DECODE(etq, 'LUNES_FIN', snap_id)) fin FROM t6.c18_snap) s
 WHERE q.snap_id > s.ini AND q.snap_id <= s.fin
   AND q.sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%')
 GROUP BY CASE WHEN q.snap_id <= s.fin THEN 'LUNES' END, q.sql_id, q.plan_hash_value
UNION ALL
SELECT 'MARTES', sql_id, plan_hash_value, executions, ROUND(buffer_gets / executions)
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND parsing_schema_name = 'T6_APP' AND is_shareable = 'Y';
PROMPT -- Lectura: el mismo SQL_ID con otro PLAN_HASH_VALUE y varias veces más lecturas por ejecución. Nadie ha tocado
PROMPT -- el código: ha cambiado el entorno del optimizador (las estadísticas). Es el síntoma de una regresión de plan.
EXIT
