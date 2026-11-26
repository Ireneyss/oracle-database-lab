-- INC-605 · verificar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
@@../_cabecera_verificar INC-605 &1 &2
ALTER SESSION SET optimizer_adaptive_plans = FALSE;
SET TERMOUT OFF
SELECT /* t6_inc605_verificar */ COUNT(*), SUM(p.importe) FROM t6.cesta k JOIN t6.pedido p ON p.id_pedido = k.id_pedido;
SET TERMOUT ON
SELECT CASE WHEN s.num_rows BETWEEN 0.9 * r.n AND 1.1 * r.n THEN 'OK    ' ELSE 'FALLO ' END
       || 'Estadísticas de CESTA: ' || s.num_rows || ' filas frente a ' || r.n || ' reales'
  FROM dba_tab_statistics s, (SELECT COUNT(*) n FROM t6.cesta) r WHERE s.owner = 'T6' AND s.table_name = 'CESTA' AND s.object_type = 'TABLE'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El informe une con HASH JOIN (sin bucles anidados por cada cesta)'
  FROM v$sql_plan WHERE operation = 'HASH JOIN' AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_inc605_verificar */%')
UNION ALL
SELECT 'INFO  Estadísticas de CESTA bloqueadas ahora: ' || NVL(stattype_locked, 'NO') || ' (válido si están al día; justifícalo en la bitácora)'
  FROM dba_tab_statistics WHERE owner = 'T6' AND table_name = 'CESTA' AND object_type = 'TABLE';
EXIT
