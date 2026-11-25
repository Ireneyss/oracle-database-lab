-- C18 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) >= 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Hay una línea base ACEPTADA y ACTIVA para el informe' AS resultado
  FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND accepted = 'YES' AND enabled = 'YES'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El informe de la aplicación se ejecuta con la línea base'
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND parsing_schema_name = 'T6_APP' AND sql_plan_baseline IS NOT NULL
UNION ALL
SELECT CASE WHEN h.histogram = 'NONE' THEN 'OK    ' ELSE 'FALLO ' END
       || 'Y eso SIN tocar las estadísticas del martes (ESTADO sigue sin histograma: ' || h.histogram || ')'
  FROM dba_tab_col_statistics h WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO'
UNION ALL
SELECT CASE WHEN b.gets * 3 < m.gets THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas por ejecución con SPM: ' || b.gets || ' frente a ' || m.gets || ' del plan del martes'
  FROM t6.c18_medida b, t6.c18_medida m WHERE b.etq = 'CON_SPM' AND m.etq = 'MARTES';
EXIT
