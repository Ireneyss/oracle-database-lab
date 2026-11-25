-- C10 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(DISTINCT plan_hash_value) >= 2 THEN 'OK    ' ELSE 'FALLO ' END
       || 'La sentencia tiene ' || COUNT(DISTINCT plan_hash_value) || ' planes: uno para P y otro para C' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c10 */%'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Hay un hijo consciente del valor (IS_BIND_AWARE = Y)'
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c10 */%' AND is_bind_aware = 'Y';
EXIT
