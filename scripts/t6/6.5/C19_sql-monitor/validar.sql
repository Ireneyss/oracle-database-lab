-- C19 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
WITH m AS (SELECT CASE WHEN sql_text LIKE '%t6_c19_ANTES%' THEN 'A' ELSE 'D' END AS v, MIN(elapsed_time) t, MIN(physical_write_bytes) w
             FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_%' GROUP BY CASE WHEN sql_text LIKE '%t6_c19_ANTES%' THEN 'A' ELSE 'D' END)
SELECT CASE WHEN COUNT(*) = 2 THEN 'OK    ' ELSE 'FALLO ' END || 'SQL Monitor tiene las dos ejecuciones (antes y después)' AS resultado FROM m
UNION ALL
SELECT CASE WHEN d.w < a.w / 2 THEN 'OK    ' ELSE 'FALLO ' END || 'Escritura en TEMP: ' || ROUND(d.w / 1048576) || ' MB frente a ' || ROUND(a.w / 1048576) || ' MB'
  FROM m a, m d WHERE a.v = 'A' AND d.v = 'D'
UNION ALL
SELECT CASE WHEN d.t < a.t THEN 'OK    ' ELSE 'FALLO ' END || 'Duración: ' || ROUND(d.t / 1000) || ' ms frente a ' || ROUND(a.t / 1000) || ' ms'
  FROM m a, m d WHERE a.v = 'A' AND d.v = 'D';
EXIT
