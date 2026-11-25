-- C06 · entender · el síntoma: una suma sobre 1 000 000 de filas en memoria tarda segundos y es casi todo CPU
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN forma FORMAT A15
SELECT REGEXP_SUBSTR(sql_text, 't6_c06 (\w+)', 1, 1, NULL, 1) AS forma, executions,
       ROUND(elapsed_time / executions / 1000) AS ms_ejec, ROUND(cpu_time / executions / 1000) AS cpu_ms, ROUND(buffer_gets / executions) AS gets
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c06%' AND command_type = 3;
PROMPT -- Lectura: unos 5 000 bloques en memoria se leen en décimas de segundo. El resto del tiempo, ¿dónde se va?
EXIT
