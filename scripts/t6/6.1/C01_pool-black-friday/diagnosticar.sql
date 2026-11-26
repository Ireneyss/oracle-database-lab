-- C01 · diagnosticar · ¿más trabajo que CPU? AAS frente a CPU_COUNT, y en qué se fue el tiempo (ASH) en cada tanda
-- Es lo mismo que hace «t6 salud», pero acotado a la ventana exacta de cada tanda.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN evento FORMAT A30
COLUMN cpu_count FORMAT A9
PROMPT == 1 · Capacidad: CPU que puede usar la instancia ==
SELECT value AS cpu_count FROM v$parameter WHERE name = 'cpu_count';
PROMPT == 2 · AAS de cada tanda = muestras de ASH / segundos de la tanda (1 muestra ≈ 1 s de una sesión activa) ==
SELECT t.etq, t.sesiones, COUNT(h.sample_id) AS muestras,
       ROUND(COUNT(h.sample_id) / (EXTRACT(MINUTE FROM (t.fin - t.ini)) * 60 + EXTRACT(SECOND FROM (t.fin - t.ini))), 1) AS aas,
       SUM(CASE WHEN h.session_state = 'ON CPU' THEN 1 ELSE 0 END) AS en_cpu,
       SUM(CASE WHEN h.session_state = 'WAITING' THEN 1 ELSE 0 END) AS esperando
  FROM t6.c01_tanda t LEFT JOIN v$active_session_history h
    ON h.sample_time BETWEEN t.ini AND t.fin AND h.module = 'tienda_web' AND h.action = t.etq
 GROUP BY t.etq, t.sesiones, t.ini, t.fin ORDER BY t.sesiones;
PROMPT == 3 · En qué esperaban las sesiones de la hora punta ==
SELECT h.action AS etq, NVL(h.event, 'ON CPU') AS evento, COUNT(*) AS muestras,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY h.action), 1) AS pct
  FROM v$active_session_history h JOIN t6.c01_tanda t ON h.sample_time BETWEEN t.ini AND t.fin AND h.action = t.etq
 WHERE h.module = 'tienda_web'
 GROUP BY h.action, NVL(h.event, 'ON CPU') ORDER BY etq, muestras DESC;
PROMPT -- Lectura: AAS por encima de CPU_COUNT = cola. «resmgr:cpu quantum» es la espera de turno de CPU que
PROMPT -- impone el gestor de recursos (en Oracle Free, el límite de 2 CPU): el trabajo no va más rápido, hace cola.
EXIT
