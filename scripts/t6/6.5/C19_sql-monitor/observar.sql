-- C19 · observar · el informe de la ejecución buena y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF LONG 1000000 LONGCHUNKSIZE 1000000 LINESIZE 220 PAGESIZE 0 TRIMSPOOL ON
SELECT DBMS_SQL_MONITOR.REPORT_SQL_MONITOR(
         sql_id => (SELECT sql_id FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_DESPUES */%'
                     ORDER BY sql_exec_start DESC FETCH FIRST 1 ROW ONLY),
         type => 'TEXT', report_level => 'BASIC +PLAN') AS informe
  FROM dual;
SET PAGESIZE 100
PROMPT == Lo que debes retener ==
PROMPT 1. SQL Monitor es el plan real con cronómetro: % de actividad, memoria y TEMP por línea, y también EN CURSO.
PROMPT 2. Vigila sola: más de 5 s de CPU o E/S, o paralela. Para una corta: /*+ MONITOR */. Requiere Tuning Pack en EE.
PROMPT 3. Para el informe en HTML (el que se adjunta a un ticket): type => 'ACTIVE' o 'HTML' y SPOOL a un archivo.
PROMPT 4. Pariente de C04: allí el desborde se veía en V$SQL_WORKAREA; aquí, en la columna Temp del informe.
EXIT
