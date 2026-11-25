-- C19 · provocar · el informe de fidelización de los lunes, en la sesión de la herramienta de informes (memoria MANUAL, 1 MB)
-- Efectos: ninguno en datos. Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
ALTER SESSION SET workarea_size_policy = MANUAL;
ALTER SESSION SET sort_area_size = 1048576;
ALTER SESSION SET hash_area_size = 2097152;
@@_informe ANTES
SELECT 'Informe terminado en ' || ROUND(elapsed_time / 1000) || ' ms (SQL_ID ' || sql_id || ')' AS resultado
  FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_ANTES */%' ORDER BY sql_exec_start DESC FETCH FIRST 1 ROW ONLY;
EXIT
