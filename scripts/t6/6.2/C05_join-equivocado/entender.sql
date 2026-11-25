-- C05 · entender · el síntoma: 60 000 filas de salida y más de medio millón de lecturas lógicas
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
SELECT sql_id, ROUND(elapsed_time / executions / 1000) AS ms_ejec, ROUND(buffer_gets / executions) AS gets_ejec,
       ROUND(rows_processed / executions) AS filas, ROUND(buffer_gets / NULLIF(rows_processed, 0), 1) AS gets_por_fila
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c p) USE_NL%t6_c05_nl%';
PROMPT -- Lectura: unas 10 lecturas lógicas por fila devuelta. ¿De dónde salen? El plan lo dice (columna Starts).
EXIT
