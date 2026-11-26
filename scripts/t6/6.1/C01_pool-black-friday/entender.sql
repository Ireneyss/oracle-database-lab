-- C01 · entender · lo que ve el negocio: llamadas por segundo (throughput) y latencia (p50, p95) de cada tanda
-- Fuente: la telemetría de la aplicación (T6.APP_LOG), no la base: así es como lo mide la web (el SLI).
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN ms_p50 FORMAT 99990.0
COLUMN ms_p95 FORMAT 99990.0
COLUMN llamadas_seg FORMAT 9990.0
PROMPT == El SLI de la web, por tanda ==
SELECT t.etq, t.sesiones, COUNT(*) AS llamadas,
       ROUND(COUNT(*) / (EXTRACT(MINUTE FROM (t.fin - t.ini)) * 60 + EXTRACT(SECOND FROM (t.fin - t.ini))), 1) AS llamadas_seg,
       ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY l.ms), 1) AS ms_p50,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY l.ms), 1) AS ms_p95
  FROM t6.c01_tanda t JOIN t6.app_log l ON l.etq = t.etq
 GROUP BY t.etq, t.sesiones, t.ini, t.fin ORDER BY t.sesiones;
PROMPT -- Lectura: con 8 veces más sesiones, ¿se atienden 8 veces más llamadas por segundo? ¿Qué le pasa a la latencia?
EXIT
