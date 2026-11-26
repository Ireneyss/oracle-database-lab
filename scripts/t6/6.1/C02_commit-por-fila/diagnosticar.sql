-- C02 · diagnosticar · ¿en qué esperó? Los eventos de espera de la sesión y lo que cuesta cada COMMIT
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN redo_kb FORMAT 999,990
PROMPT == 1 · Lo que midió la propia sesión (V$MYSTAT y V$SESSION_EVENT, antes y después) ==
SELECT etq, commits, esperas_lfs AS esperas_log_file_sync, ms_lfs AS ms_en_log_file_sync,
       ROUND(ms_lfs / NULLIF(esperas_lfs, 0), 3) AS ms_por_espera, ROUND(redo_bytes / 1024) AS redo_kb
  FROM t6.c02_medida WHERE etq = 'POR_FILA';
PROMPT == 2 · El mismo evento en toda la instancia (acumulado desde el arranque) ==
SELECT event, total_waits, ROUND(time_waited_micro / 1e6, 1) AS segundos,
       ROUND(time_waited_micro / NULLIF(total_waits, 0) / 1000, 3) AS ms_medio
  FROM v$system_event WHERE event IN ('log file sync', 'log file parallel write');
PROMPT -- Lectura: «log file sync» = la sesión espera a que LGWR escriba su redo en disco al confirmar (COMMIT).
PROMPT -- Un COMMIT por fila = 20 000 esperas. La causa no es el disco: es el diseño de la transacción.
EXIT
