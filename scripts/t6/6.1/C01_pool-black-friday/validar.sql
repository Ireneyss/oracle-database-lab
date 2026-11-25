-- C01 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
WITH m AS (SELECT t.etq, COUNT(*) / (EXTRACT(MINUTE FROM (t.fin - t.ini)) * 60 + EXTRACT(SECOND FROM (t.fin - t.ini))) AS tps,
                  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY l.ms) AS p95
             FROM t6.c01_tanda t JOIN t6.app_log l ON l.etq = t.etq GROUP BY t.etq, t.ini, t.fin)
SELECT CASE WHEN n2.tps >= 0.85 * n8.tps THEN 'OK    ' ELSE 'FALLO ' END
       || 'Con 2 sesiones se atiende lo mismo que con 8: ' || ROUND(n2.tps, 1) || ' frente a ' || ROUND(n8.tps, 1) || ' llamadas/s' AS resultado
  FROM m n2, m n8 WHERE n2.etq = 'C01_N2' AND n8.etq = 'C01_N8'
UNION ALL
SELECT CASE WHEN n2.p95 < 0.6 * n8.p95 THEN 'OK    ' ELSE 'FALLO ' END
       || 'La latencia p95 baja de ' || ROUND(n8.p95) || ' ms a ' || ROUND(n2.p95) || ' ms (menos cola)'
  FROM m n2, m n8 WHERE n2.etq = 'C01_N2' AND n8.etq = 'C01_N8'
UNION ALL
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Línea base del panel registrada en T6.LINEA_BASE (caso C01)'
  FROM t6.linea_base WHERE caso = 'C01' AND sql_id IS NOT NULL;
EXIT
