-- C19 · diagnosticar · el informe de SQL Monitor: por cada línea del plan, filas reales, memoria, TEMP y % de actividad
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF LONG 1000000 LONGCHUNKSIZE 1000000 LINESIZE 220 PAGESIZE 0 TRIMSPOOL ON
SELECT DBMS_SQL_MONITOR.REPORT_SQL_MONITOR(
         sql_id => (SELECT sql_id FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_ANTES */%'
                     ORDER BY sql_exec_start DESC FETCH FIRST 1 ROW ONLY),
         type => 'TEXT', report_level => 'TYPICAL -SQL_TEXT') AS informe
  FROM dual;
PROMPT -- Lectura: mira Write Bytes y Temp (Max) por línea: la WINDOW SORT (Id 10) y los HASH GROUP BY escriben en TEMP
PROMPT -- decenas de MB con Mem (Max) de 1 a 3 MB. La causa no es el plan, es la memoria de trabajo de la sesión
PROMPT -- (MANUAL, 1 MB). En un informe de minutos, la columna Activity (%) dice además qué línea se lleva el tiempo.
EXIT
