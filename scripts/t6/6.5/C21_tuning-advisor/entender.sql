-- C21 · entender · qué es y qué no es un asesor: lo que va a analizar SQL Tuning Advisor y lo que NO puede ver
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN sql_text FORMAT A80
SELECT sql_id, parsing_schema_name AS esquema, executions, ROUND(buffer_gets / executions) AS gets_ejec, sql_text
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1;
PROMPT -- Lectura: el asesor ve UNA sentencia y sus estadísticas; no ve el código de la aplicación que la llama con un
PROMPT -- NUMBER. Analiza estadísticas, rutas de acceso, estructura del SQL y perfiles, y PROPONE. No despliega nada.
EXIT
