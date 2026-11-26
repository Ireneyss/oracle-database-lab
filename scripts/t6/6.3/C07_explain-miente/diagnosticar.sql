-- C07 · diagnosticar · lo que HIZO de verdad: el plan del cursor de la aplicación en memoria (DISPLAY_CURSOR)
-- Es «t6 plan SQL_ID» con el SQL_ID de la pantalla. El SQL_ID se busca por su marca (t6_cp_v1).
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF LINESIZE 170
COLUMN ms_ejec FORMAT 9990.00
PROMPT == 1 · El cursor de la pantalla: SQL_ID, plan y coste por ejecución ==
SELECT sql_id, plan_hash_value, executions, ROUND(elapsed_time / executions / 1000, 2) AS ms_ejec,
       ROUND(buffer_gets / executions) AS gets_ejec
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%';
PROMPT == 2 · Su plan real, con los predicados ==
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1), NULL, 'TYPICAL -BYTES +PEEKED_BINDS'));
PROMPT -- Lectura: filter(TO_NUMBER("CODIGO_POSTAL")=:B1). Oracle convierte la COLUMNA para compararla con un número:
PROMPT -- el índice sobre CODIGO_POSTAL (texto) ya no sirve y se recorre la tabla entera en cada búsqueda.
EXIT
