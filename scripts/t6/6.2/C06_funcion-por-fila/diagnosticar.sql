-- C06 · diagnosticar · el modelo de tiempo: SQL que llama a PL/SQL un millón de veces (cambio de contexto por fila)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN forma FORMAT A15
SELECT REGEXP_SUBSTR(sql_text, 't6_c06 (\w+)', 1, 1, NULL, 1) AS forma, ROUND(elapsed_time / executions / 1000) AS ms_ejec,
       ROUND(plsql_exec_time / executions / 1000) AS ms_en_plsql, ROUND(100 * plsql_exec_time / NULLIF(elapsed_time, 0)) AS pct_plsql
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c06%' AND command_type = 3;
PROMPT -- Lectura: PLSQL_EXEC_TIME es el tiempo dentro de la función. Una llamada por fila = 1 000 000 de cambios SQL ↔ PL/SQL.
EXIT
