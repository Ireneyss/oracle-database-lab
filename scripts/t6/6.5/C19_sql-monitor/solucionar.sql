-- C19 · solucionar · la misma sesión con la memoria automática (PGA_AGGREGATE_TARGET) y el mismo informe
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
ALTER SESSION SET workarea_size_policy = AUTO;
SET ECHO OFF
@@_informe DESPUES
SELECT 'Informe terminado en ' || ROUND(elapsed_time / 1000) || ' ms, ' || ROUND(physical_write_bytes / 1048576) || ' MB escritos en TEMP' AS resultado
  FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_DESPUES */%' ORDER BY sql_exec_start DESC FETCH FIRST 1 ROW ONLY;
EXIT
