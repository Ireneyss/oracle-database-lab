-- C13 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF SERVEROUTPUT OFF
DELETE FROM plan_table;
EXPLAIN PLAN FOR SELECT * FROM t6.pedido WHERE estado = 'E';
SELECT CASE WHEN e.c BETWEEN 0.9 * r.n AND 1.1 * r.n THEN 'OK    ' ELSE 'FALLO ' END
       || 'Estimación de pedidos E: ' || e.c || ' (reales ' || r.n || ')' AS resultado
  FROM (SELECT cardinality c FROM plan_table WHERE id = 1) e, (SELECT COUNT(*) n FROM t6.pedido WHERE estado = 'E') r
UNION ALL
SELECT CASE WHEN histogram = 'FREQUENCY' THEN 'OK    ' ELSE 'FALLO ' END || 'ESTADO tiene histograma ' || histogram
  FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO'
UNION ALL
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'No quedan estadísticas pendientes sin publicar'
  FROM dba_tab_pending_stats WHERE owner = 'T6' AND table_name = 'PEDIDO'
UNION ALL
SELECT CASE WHEN DBMS_STATS.GET_PREFS('PUBLISH', 'T6', 'PEDIDO') = 'TRUE' THEN 'OK    ' ELSE 'FALLO ' END
       || 'La preferencia PUBLISH ha vuelto a TRUE' FROM dual;
ROLLBACK;
EXIT
