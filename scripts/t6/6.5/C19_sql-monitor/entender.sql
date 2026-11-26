-- C19 · entender · el informe tarda; ¿cuánto, cuántas veces y con qué? Lo que guarda SQL Monitor de cada ejecución
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN sql_exec_start FORMAT A19
COLUMN status FORMAT A16
SELECT sql_id, status, TO_CHAR(sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start, ROUND(elapsed_time / 1000) AS ms,
       buffer_gets, ROUND(physical_read_bytes / 1048576) AS mb_leidos, ROUND(physical_write_bytes / 1048576) AS mb_escritos
  FROM v$sql_monitor WHERE sql_text LIKE 'SELECT /*+ MONITOR */ /* t6_c19_%' ORDER BY sql_exec_start;
PROMPT -- Lectura: SQL Monitor vigila solo las sentencias de más de 5 s, las paralelas o las que piden /*+ MONITOR */.
PROMPT -- Escribir MB a disco en una consulta de lectura es la pista: algo se está desbordando a TEMP.
EXIT
