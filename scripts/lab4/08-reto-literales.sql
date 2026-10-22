-- scripts/lab4/08-reto-literales.sql — reto G: sentencias que la aplicación ejecuta con literales
-- Misma sentencia con distintos literales = mismo FORCE_MATCHING_SIGNATURE y un cursor por cada valor.
SET LINESIZE 180 PAGESIZE 50 FEEDBACK OFF
COLUMN ejemplo FORMAT A70 TRUNCATED
SELECT con_id, force_matching_signature, COUNT(*) AS cursores,
       SUM(executions) AS ejecuciones, MIN(sql_text) AS ejemplo
  FROM v$sql
 WHERE force_matching_signature <> 0
 GROUP BY con_id, force_matching_signature
HAVING COUNT(*) > 50
 ORDER BY cursores DESC;
EXIT
