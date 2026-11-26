-- C12 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO
SELECT CASE WHEN s.num_rows BETWEEN 0.9 * r.n AND 1.1 * r.n AND s.stale_stats = 'NO' THEN 'OK    ' ELSE 'FALLO ' END
       || 'Estadísticas de CARRITO al día: ' || s.num_rows || ' filas (reales ' || r.n || '), STALE = ' || s.stale_stats AS resultado
  FROM dba_tab_statistics s, (SELECT COUNT(*) n FROM t6.carrito) r WHERE s.owner = 'T6' AND s.table_name = 'CARRITO'
UNION ALL
SELECT CASE WHEN d.g * 2 < a.g THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas lógicas del informe: ' || d.g || ' frente a ' || a.g
  FROM (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_despues%') d,
       (SELECT MAX(buffer_gets / executions) g FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_antes%') a
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El informe usa ahora HASH JOIN'
  FROM v$sql_plan WHERE operation = 'HASH JOIN'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_despues%');
EXIT
