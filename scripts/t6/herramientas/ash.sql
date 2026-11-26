-- =====================================================================================================
-- herramientas/ash.sql · Active Session History: quién, qué y en qué esperaba, minuto a minuto
-- Uso: t6 ash [minutos] [sql_id|módulo|-]      Licencia: Diagnostics Pack (en Free viene activa)
-- ASH muestrea cada segundo las sesiones ACTIVAS: 1 muestra ≈ 1 segundo de DB time. Por eso «muestras» es tiempo.
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN evento FORMAT A34
COLUMN module FORMAT A16
COLUMN action FORMAT A14
PROMPT == 1 · Minuto a minuto: sesiones activas medias (muestras / 60) ==
SELECT TO_CHAR(TRUNC(sample_time, 'MI'), 'HH24:MI') AS minuto, ROUND(COUNT(*) / 60, 2) AS aas,
       SUM(CASE WHEN session_state = 'ON CPU' THEN 1 ELSE 0 END) AS en_cpu,
       SUM(CASE WHEN session_state = 'WAITING' THEN 1 ELSE 0 END) AS esperando
  FROM v$active_session_history
 WHERE sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&1, 'MINUTE') AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND ('&2' = '-' OR sql_id = '&2' OR module = '&2')
 GROUP BY TRUNC(sample_time, 'MI') ORDER BY 1;
PROMPT == 2 · Por SQL_ID, módulo y evento ==
SELECT sql_id, module, action, NVL(event, 'ON CPU') AS evento, COUNT(*) AS muestras
  FROM v$active_session_history
 WHERE sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&1, 'MINUTE') AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND ('&2' = '-' OR sql_id = '&2' OR module = '&2')
 GROUP BY sql_id, module, action, NVL(event, 'ON CPU') ORDER BY muestras DESC FETCH FIRST 8 ROWS ONLY;
PROMPT == 3 · Sesiones bloqueadas por otra (si las hay) ==
SELECT session_id AS sid, blocking_session AS bloqueador, NVL(event, 'ON CPU') AS evento, COUNT(*) AS muestras
  FROM v$active_session_history
 WHERE sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&1, 'MINUTE') AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND blocking_session IS NOT NULL
 GROUP BY session_id, blocking_session, NVL(event, 'ON CPU') ORDER BY muestras DESC FETCH FIRST 5 ROWS ONLY;
EXIT
