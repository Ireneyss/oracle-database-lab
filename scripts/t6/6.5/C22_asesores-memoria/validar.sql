-- C22 · validar · cada línea dice OK o FALLO
@@../../_formato
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El asesor de la SGA tiene ' || COUNT(*) || ' tamaños estimados' AS resultado FROM v$sga_target_advice
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El asesor de la PGA tiene ' || COUNT(*) || ' tamaños estimados' FROM v$pga_target_advice
UNION ALL
SELECT CASE WHEN value > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'PGA automática activa: pga_aggregate_target = ' || ROUND(value / 1048576) || ' MB'
  FROM v$parameter WHERE name = 'pga_aggregate_target'
UNION ALL
SELECT CASE WHEN value = 'AUTO' THEN 'OK    ' ELSE 'FALLO ' END || 'workarea_size_policy = ' || value || ' (nadie la ha dejado en MANUAL)'
  FROM v$parameter WHERE name = 'workarea_size_policy';
EXIT
