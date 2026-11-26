-- INC-611 · verificar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN ciu NEW_VALUE ciudad
COLUMN com NEW_VALUE comunidad
SELECT 'Ciudad' || LPAD(100 + MOD(&1 * 53, 1800), 4, '0') AS ciu, 'COM' || LPAD(MOD(100 + MOD(&1 * 53, 1800), 17) + 1, 2, '0') AS com FROM dual;
SET TERMOUT ON
@@../_cabecera_verificar INC-611 &1 &2
DELETE FROM plan_table;
EXPLAIN PLAN FOR SELECT * FROM t6.cliente c WHERE c.ciudad = '&ciudad' AND c.comunidad = '&comunidad';
SELECT CASE WHEN e.c BETWEEN 0.5 * r.n AND 2 * r.n THEN 'OK    ' ELSE 'FALLO ' END
       || 'Clientes estimados en &ciudad / &comunidad: ' || e.c || ' (reales ' || r.n || ')'
  FROM (SELECT cardinality c FROM plan_table WHERE id = 0) e,
       (SELECT COUNT(*) n FROM t6.cliente WHERE ciudad = '&ciudad' AND comunidad = '&comunidad') r
UNION ALL
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Existe la extensión (CIUDAD, COMUNIDAD) con estadísticas'
  FROM dba_stat_extensions x JOIN dba_tab_col_statistics s ON s.owner = x.owner AND s.table_name = x.table_name AND s.column_name = x.extension_name
 WHERE x.owner = 'T6' AND x.table_name = 'CLIENTE' AND REPLACE(DBMS_LOB.SUBSTR(x.extension, 200, 1), '"') = '(CIUDAD,COMUNIDAD)';
ROLLBACK;
EXIT
