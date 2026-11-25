-- =====================================================================================================
-- herramientas/top.sql · las sentencias que más pesan, por ejecución y en total (V$SQLSTATS)
-- Uso: t6 top [n] [orden] [filtro]     orden: elapsed (defecto) | cpu | gets | ejec · filtro: texto (LIKE) o -
-- Las cifras son ACUMULADAS desde que el cursor entró en la shared pool: compáralas con «t6 base» o con AWR (deltas).
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN texto FORMAT A42
COLUMN seg_total FORMAT 99990.0
COLUMN ms_ejec FORMAT 9999990.0
PROMPT == Top &1 sentencias por &2 (filtro: &3) ==
SELECT sql_id, plan_hash_value AS plan_hash, executions AS ejec, ROUND(elapsed_time / 1e6, 1) AS seg_total,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 1) AS ms_ejec,
       ROUND(buffer_gets / NULLIF(executions, 0)) AS gets_ejec,
       ROUND(rows_processed / NULLIF(executions, 0)) AS filas_ejec,
       SUBSTR(REGEXP_REPLACE(sql_text, '\s+', ' '), 1, 42) AS texto
  FROM v$sqlstats
 WHERE con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND ('&3' = '-' OR UPPER(sql_text) LIKE UPPER('%&3%'))
   AND sql_text NOT LIKE '%v$sqlstats%' AND sql_text NOT LIKE 'BEGIN%' AND sql_text NOT LIKE 'DECLARE%'
 ORDER BY CASE LOWER('&2') WHEN 'cpu' THEN cpu_time WHEN 'gets' THEN buffer_gets WHEN 'ejec' THEN executions
          ELSE elapsed_time END DESC
 FETCH FIRST &1 ROWS ONLY;
PROMPT -- Siguiente paso: «t6 plan SQL_ID» para ver el plan real de la que más pesa.
EXIT
