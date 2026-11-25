-- C04 · observar · las tres ejecuciones lado a lado, y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN etiqueta FORMAT A10
COLUMN mb_optimo FORMAT 9990.0
COLUMN mb_temp FORMAT 9990.0
SELECT modo, politica, filas, ms, temp_escritos, temp_leidos FROM t6.c04_medida ORDER BY ms DESC;
SELECT REGEXP_SUBSTR(s.sql_text, 't6_informe_(\w+)', 1, 1, NULL, 1) AS etiqueta, w.operation_type,
       ROUND(w.estimated_optimal_size / 1048576, 1) AS mb_optimo, w.last_execution, w.optimal_executions AS optimas,
       w.onepass_executions AS una_pasada, w.multipasses_executions AS varias
  FROM v$sql_workarea w JOIN v$sql s ON s.sql_id = w.sql_id AND s.child_number = w.child_number
 WHERE s.sql_text LIKE 'SELECT /*+ t6_informe%';
PROMPT == Lo que debes retener ==
PROMPT 1. Ordenar, agrupar y los hash join usan un área de trabajo en la PGA: OPTIMAL, ONE PASS o MULTI-PASS.
PROMPT 2. Antes de dar más memoria, busca quién la limita (política MANUAL heredada, PGA_AGGREGATE_TARGET de la PDB).
PROMPT 3. Reducir antes de ordenar vale más que ordenar mejor: un TOP-N (SORT ORDER BY STOPKEY) necesita KB, no MB.
PROMPT 4. Variante de examen: «TEMP se llena»: V$TEMPSEG_USAGE dice quién; V$SQL_WORKAREA_ACTIVE, qué operación.
EXIT
