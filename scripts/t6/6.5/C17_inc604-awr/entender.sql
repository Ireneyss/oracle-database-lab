-- C17 · entender · el síntoma con números: el SLI (latencia p95 de la búsqueda) frente al SLO acordado (p95 < 20 ms)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN etq FORMAT A8
COLUMN slo FORMAT A16
SELECT etq, COUNT(*) AS llamadas, ROUND(COUNT(*) / 120 / 3, 1) AS llamadas_seg_sesion,
       ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ms), 1) AS p50_ms,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms), 1) AS p95_ms,
       CASE WHEN PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms) < 20 THEN 'CUMPLE' ELSE 'INCUMPLE (< 20)' END AS slo
  FROM t6.app_log WHERE etq = 'C17_V1' GROUP BY etq;
SELECT etq, snap_id, TO_CHAR(ts, 'HH24:MI:SS') AS hora FROM t6.c17_snap ORDER BY snap_id;
PROMPT -- Lectura: el ticket dice «va lenta»; la telemetría lo convierte en un número que se puede comparar después:
PROMPT -- la p95 incumple el SLO. Y tenemos un intervalo AWR que cubre exactamente la carga (las dos instantáneas).
PROMPT -- Lo mismo con la caja de herramientas:   t6 awr lista
EXIT
