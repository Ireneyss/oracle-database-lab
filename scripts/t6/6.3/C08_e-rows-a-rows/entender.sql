-- C08 · entender · ¿cuántos clientes hay de verdad, y cuántos cree el optimizador? (la pregunta que hay que hacerse)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == La realidad ==
SELECT COUNT(*) AS clientes_reales FROM t6.cliente WHERE ciudad = 'Ciudad0042' AND comunidad = 'COM09';
SELECT MAX(n) AS max_comunidades_por_ciudad FROM (SELECT ciudad, COUNT(DISTINCT comunidad) n FROM t6.cliente GROUP BY ciudad);
PROMPT == Lo que sabe el optimizador de cada columna POR SEPARADO ==
SELECT column_name, num_distinct, histogram FROM dba_tab_col_statistics
 WHERE owner = 'T6' AND table_name = 'CLIENTE' AND column_name IN ('CIUDAD', 'COMUNIDAD');
SELECT num_rows, ROUND(num_rows / 2000 / 17, 1) AS estimacion_independiente FROM dba_tables WHERE owner = 'T6' AND table_name = 'CLIENTE';
PROMPT -- Lectura: 100 000 × 1/2 000 × 1/17 ≈ 3 clientes. Son 56: el error está en suponer que son independientes.
EXIT
