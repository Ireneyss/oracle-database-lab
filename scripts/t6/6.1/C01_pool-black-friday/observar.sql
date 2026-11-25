-- C01 · observar · la ley de Little con tus números, y lo que debes retener
-- Concurrencia media = throughput × latencia media. Si la CPU es el límite, el throughput se estanca en ≈ capacidad
-- y toda concurrencia extra se convierte en latencia (cola). Variante de examen: «¿subo PROCESSES o el pool?» No.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN concurrencia_little FORMAT 990.0
COLUMN llamadas_seg FORMAT 9990.0
COLUMN ms_medio FORMAT 99990.0
PROMPT == Las tres tandas y la ley de Little (throughput × latencia media ≈ sesiones) ==
SELECT t.etq, t.sesiones,
       ROUND(COUNT(*) / (EXTRACT(MINUTE FROM (t.fin - t.ini)) * 60 + EXTRACT(SECOND FROM (t.fin - t.ini))), 1) AS llamadas_seg,
       ROUND(AVG(l.ms), 1) AS ms_medio,
       ROUND(COUNT(*) / (EXTRACT(MINUTE FROM (t.fin - t.ini)) * 60 + EXTRACT(SECOND FROM (t.fin - t.ini))) * AVG(l.ms) / 1000, 1) AS concurrencia_little
  FROM t6.c01_tanda t JOIN t6.app_log l ON l.etq = t.etq
 GROUP BY t.etq, t.sesiones, t.ini, t.fin ORDER BY t.sesiones;
PROMPT == Lo que debes retener ==
PROMPT 1. «Va lento» se convierte en números: throughput (llamadas/s) y latencia (p95) desde la telemetría (SLI).
PROMPT 2. AAS > CPU_COUNT significa cola: el tiempo extra no es trabajo, es espera (resmgr:cpu quantum, ON CPU en cola).
PROMPT 3. Más sesiones no es más rendimiento cuando el recurso ya está saturado: se dimensiona el pool a la capacidad.
PROMPT 4. Antes de tocar el SQL se registra la línea base (sql_id, plan_hash, ms y gets por ejecución): t6 base ver
EXIT
