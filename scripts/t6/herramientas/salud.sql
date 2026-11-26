-- =====================================================================================================
-- herramientas/salud.sql · «¿cómo está la base AHORA?» · primer paso del playbook PB-1 (La base va lenta)
-- Uso: t6 salud [minutos]      (por defecto, los últimos 5 minutos)        Solo lectura. Licencia: ASH (Diagnostics)
-- Responde, en este orden: 1) ¿hay más trabajo que CPU? (AAS frente a CPU_COUNT) · 2) ¿en qué se va el tiempo?
--   (CPU o esperas, por clase y evento, desde ASH) · 3) ¿quién lo consume? (SQL_ID y módulo con más muestras)
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
DEFINE min = &1
COLUMN valor FORMAT 9990.00
COLUMN pct FORMAT 990.0
COLUMN evento FORMAT A40
COLUMN semaforo FORMAT A100
PROMPT == 1 · Carga frente a capacidad: AAS por minuto (V$CON_SYSMETRIC_HISTORY) y CPU_COUNT ==
SELECT TO_CHAR(end_time, 'HH24:MI') AS minuto, ROUND(value, 2) AS aas
  FROM v$con_sysmetric_history
 WHERE metric_name = 'Average Active Sessions' AND group_id = 18 AND end_time > SYSDATE - &min / 1440
 ORDER BY end_time;
SELECT CASE WHEN NVL(MAX(a.value), 0) > c.cpu THEN 'ROJO     AAS máximo ' || ROUND(MAX(a.value), 1) || ' > CPU_COUNT ' || c.cpu || ': hay cola (trabajo esperando CPU o recursos)'
            WHEN NVL(MAX(a.value), 0) > c.cpu * 0.7 THEN 'AMARILLO AAS máximo ' || ROUND(MAX(a.value), 1) || ' cerca de CPU_COUNT ' || c.cpu
            ELSE 'VERDE    AAS máximo ' || ROUND(NVL(MAX(a.value), 0), 1) || ' con CPU_COUNT ' || c.cpu || ': hay holgura' END AS semaforo
  FROM v$con_sysmetric_history a,
       (SELECT TO_NUMBER(value) cpu FROM v$parameter WHERE name = 'cpu_count') c
 WHERE a.metric_name = 'Average Active Sessions' AND a.group_id = 18 AND a.end_time > SYSDATE - &min / 1440
 GROUP BY c.cpu;
PROMPT == 2 · En qué se va el tiempo (ASH, muestras de 1 s de sesiones activas de esta PDB) ==
SELECT NVL(wait_class, 'CPU') AS wait_class, NVL(event, 'ON CPU') AS evento, COUNT(*) AS muestras,
       ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (), 1) AS pct
  FROM v$active_session_history
 WHERE sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&min, 'MINUTE') AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
 GROUP BY NVL(wait_class, 'CPU'), NVL(event, 'ON CPU') ORDER BY muestras DESC FETCH FIRST 6 ROWS ONLY;
PROMPT == 3 · Quién lo consume: SQL_ID y módulo con más muestras ==
COLUMN module FORMAT A16
COLUMN action FORMAT A14
COLUMN texto FORMAT A44
SELECT h.sql_id, h.module, h.action, COUNT(*) AS muestras, ROUND(100 * RATIO_TO_REPORT(COUNT(*)) OVER (), 1) AS pct,
       (SELECT SUBSTR(MAX(s.sql_text), 1, 44) FROM v$sqlstats s WHERE s.sql_id = h.sql_id) AS texto
  FROM v$active_session_history h
 WHERE h.sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&min, 'MINUTE') AND h.con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND h.sql_id IS NOT NULL
 GROUP BY h.sql_id, h.module, h.action ORDER BY muestras DESC FETCH FIRST 5 ROWS ONLY;
PROMPT -- Siguiente paso: con el SQL_ID de arriba, «t6 plan SQL_ID» (playbook PB-2). Con esperas de una sola clase, PB-1 rama 2.
EXIT
