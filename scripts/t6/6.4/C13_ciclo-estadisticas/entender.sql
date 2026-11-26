-- C13 · entender · ¿cuántos pedidos 'E' cree el optimizador que hay, y cuántos hay?
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
DELETE FROM plan_table;
EXPLAIN PLAN FOR SELECT * FROM t6.pedido WHERE estado = 'E';
SELECT 'estimadas' AS fuente, cardinality AS filas FROM plan_table WHERE id = 1
UNION ALL SELECT 'reales', COUNT(*) FROM t6.pedido WHERE estado = 'E';
ROLLBACK;
PROMPT -- Lectura: sin histograma, el optimizador reparte las filas por igual entre los 4 estados (1/4 = 250 000).
EXIT
