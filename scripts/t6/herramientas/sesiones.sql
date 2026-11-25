-- =====================================================================================================
-- herramientas/sesiones.sql · quién está trabajando AHORA en FREEPDB1 (sesiones activas de usuario)
-- Uso: t6 sesiones [módulo|-]
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN module FORMAT A14
COLUMN action FORMAT A14
COLUMN evento FORMAT A30
SELECT sid, serial#, username, module, action, sql_id, status, NVL2(blocking_session, 'SI ' || blocking_session, '-') AS bloqueada,
       CASE WHEN state = 'WAITING' THEN event ELSE 'ON CPU' END AS evento, last_call_et AS seg_en_llamada
  FROM v$session
 WHERE type = 'USER' AND con_id = SYS_CONTEXT('USERENV', 'CON_ID') AND sid <> SYS_CONTEXT('USERENV', 'SID')
   AND ('&1' = '-' OR module = '&1')
 ORDER BY status, last_call_et DESC FETCH FIRST 15 ROWS ONLY;
EXIT
