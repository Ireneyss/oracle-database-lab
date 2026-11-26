-- C03 · entender · el síntoma: CPU alta con consultas triviales (una fila por clave primaria) y la shared pool llena
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == 1 · Lo que costó cada ficha (una consulta por clave primaria debería costar décimas de milisegundo) ==
SELECT modo, llamadas, ms_total, cpu_ms, ROUND(ms_total / llamadas, 3) AS ms_por_ficha FROM t6.c03_medida WHERE modo = 'LITERAL';
PROMPT == 2 · Lo que ha dejado en la shared pool: un cursor por cada valor distinto ==
SELECT COUNT(*) AS cursores, SUM(executions) AS ejecuciones, ROUND(SUM(sharable_mem) / 1024) AS kb_shared_pool
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_ficha */%';
SELECT sql_id, executions, SUBSTR(sql_text, 1, 80) AS sql_text FROM v$sql
 WHERE sql_text LIKE 'SELECT /* t6_ficha */%' AND ROWNUM <= 3;
EXIT
