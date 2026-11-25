-- C08 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Existe el grupo de columnas (CIUDAD, COMUNIDAD) en T6.CLIENTE' AS resultado
  FROM dba_stat_extensions WHERE owner = 'T6' AND table_name = 'CLIENTE' AND REPLACE(DBMS_LOB.SUBSTR(extension, 200, 1), '"') = '(CIUDAD,COMUNIDAD)'
UNION ALL
SELECT CASE WHEN MAX(p.cardinality) BETWEEN 28 AND 112 THEN 'OK    ' ELSE 'FALLO ' END
       || 'La estimación de clientes es ahora ' || MAX(p.cardinality) || ' (reales: ' || MAX(r.n) || ')'
  FROM v$sql_plan p, (SELECT COUNT(*) n FROM t6.cliente WHERE ciudad = 'Ciudad0042' AND comunidad = 'COM09') r WHERE p.object_name = 'CLIENTE' AND p.operation = 'TABLE ACCESS'
   AND p.sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_despues%')
UNION ALL
SELECT CASE WHEN MAX(p.cardinality) < 10 THEN 'OK    ' ELSE 'FALLO ' END
       || 'Antes, la estimación era ' || MAX(p.cardinality) || ' (el error que había que encontrar)'
  FROM v$sql_plan p WHERE p.object_name = 'CLIENTE' AND p.operation = 'TABLE ACCESS'
   AND p.sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_antes%');
EXIT
