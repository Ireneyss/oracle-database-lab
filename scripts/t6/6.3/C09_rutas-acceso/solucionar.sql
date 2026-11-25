-- C09 · solucionar · la pregunta 1 reescrita con la columna LIMPIA (importe > 499.5 en vez de importe * 2 > 999)
-- Aquí la ruta no cambia (el índice empieza por CANAL), pero mira la columna Rows: con la expresión, el optimizador no
-- puede usar las estadísticas de IMPORTE y aplica una conjetura fija (5 % = 50 000 filas); limpia, estima 10 980.
-- Una estimación mala hoy es un plan malo mañana (en un join, en un índice que empiece por IMPORTE...).
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
COLUMN plan_table_output FORMAT A100
EXPLAIN PLAN FOR SELECT canal, importe FROM t6.pedido WHERE importe > 499.5;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +ROWS +COST +PREDICATE'));
EXPLAIN PLAN FOR SELECT canal, importe FROM t6.pedido WHERE importe * 2 > 999;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +ROWS +COST +PREDICATE'));
EXIT
