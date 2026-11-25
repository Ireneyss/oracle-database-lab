-- C12 · entender · lo que tiene el optimizador frente a lo que hay
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
SELECT 'CARRITO según las estadísticas' AS fuente, num_rows AS filas, last_analyzed FROM dba_tables WHERE owner = 'T6' AND table_name = 'CARRITO'
UNION ALL
SELECT 'CARRITO de verdad', COUNT(*), NULL FROM t6.carrito;
PROMPT -- Lectura: el optimizador decide con lo que CREE que hay. 100 filas frente a 200 100: un error de 2 000 veces.
EXIT
