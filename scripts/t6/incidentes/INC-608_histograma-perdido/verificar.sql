-- INC-608 · verificar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN v NEW_VALUE valor
SELECT CASE MOD(&1, 3) WHEN 0 THEN 'P' WHEN 1 THEN 'D' ELSE 'P' END AS v FROM dual;
SET TERMOUT ON
@@../_cabecera_verificar INC-608 &1 &2
DELETE FROM plan_table;
EXPLAIN PLAN FOR SELECT COUNT(*), SUM(importe), MAX(fecha_pedido) FROM t6.pedido WHERE estado = '&valor';
SELECT CASE WHEN e.c BETWEEN 0.8 * r.n AND 1.2 * r.n THEN 'OK    ' ELSE 'FALLO ' END
       || 'Estimación para estado = ''&valor'': ' || e.c || ' filas (reales ' || r.n || ')'
  FROM (SELECT MAX(cardinality) c FROM plan_table WHERE object_name = 'PEDIDO' OR object_name LIKE 'IX_T6%') e,
       (SELECT COUNT(*) n FROM t6.pedido WHERE estado = '&valor') r
UNION ALL
SELECT CASE WHEN histogram <> 'NONE' THEN 'OK    ' ELSE 'FALLO ' END || 'ESTADO tiene histograma: ' || histogram
  FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO'
UNION ALL
SELECT CASE WHEN UPPER(p) <> 'FOR ALL COLUMNS SIZE 1' THEN 'OK    ' ELSE 'FALLO ' END
       || 'La próxima recogida conservará el histograma: METHOD_OPT = ' || p
  FROM (SELECT DBMS_STATS.GET_PREFS('METHOD_OPT', 'T6', 'PEDIDO') p FROM dual);
ROLLBACK;
EXIT
