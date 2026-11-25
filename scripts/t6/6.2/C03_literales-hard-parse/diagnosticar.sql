-- C03 · diagnosticar · ¿es el análisis? Hard parses, tiempo de análisis y la firma que delata los literales
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN force_matching_signature FORMAT 99999999999999999999 HEADING FIRMA_FORCE
PROMPT == 1 · La sesión: cuántos análisis completos (hard parse) y cuánto tiempo de análisis ==
SELECT modo, llamadas, hard_parses, ms_analisis, ROUND(100 * ms_analisis / ms_total) AS pct_tiempo_analizando FROM t6.c03_medida WHERE modo = 'LITERAL';
PROMPT == 2 · La firma: textos distintos que serían IGUALES con variables (FORCE_MATCHING_SIGNATURE) ==
SELECT force_matching_signature, COUNT(*) AS sql_ids_distintos, SUM(executions) AS ejecuciones
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_ficha */%'
 GROUP BY force_matching_signature ORDER BY 2 DESC FETCH FIRST 3 ROWS ONLY;
PROMPT == 3 · El modelo de tiempo de la PDB: el análisis completo pesa en el DB time ==
SELECT stat_name, ROUND(value / 1e6, 2) AS segundos FROM v$con_sys_time_model
 WHERE con_id = SYS_CONTEXT('USERENV', 'CON_ID') AND stat_name IN ('DB time', 'parse time elapsed', 'hard parse elapsed time') ORDER BY value DESC;
PROMPT -- Lectura: una firma con miles de SQL_ID ejecutados una vez = la aplicación no usa variables de enlace.
EXIT
