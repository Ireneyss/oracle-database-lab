-- C09 · validar · cada línea dice OK o FALLO (se comprueba la ruta que elige el optimizador para cada forma)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
DELETE FROM plan_table WHERE statement_id LIKE 'C09%';
EXPLAIN PLAN SET STATEMENT_ID = 'C09_2' FOR SELECT * FROM t6.pedido WHERE id_pedido = 4711;
EXPLAIN PLAN SET STATEMENT_ID = 'C09_5' FOR SELECT COUNT(*) FROM t6.pedido;
EXPLAIN PLAN SET STATEMENT_ID = 'C09_6' FOR SELECT canal, importe FROM t6.pedido WHERE importe = 123.45;
EXPLAIN PLAN SET STATEMENT_ID = 'C09_7' FOR SELECT * FROM t6.pedido WHERE id_cliente > 20000;
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || '2 · clave primaria: INDEX UNIQUE SCAN' AS resultado FROM plan_table WHERE statement_id = 'C09_2' AND options = 'UNIQUE SCAN'
UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || '5 · COUNT(*): INDEX FAST FULL SCAN' FROM plan_table WHERE statement_id = 'C09_5' AND options = 'FAST FULL SCAN'
UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || '6 · segunda columna del índice: INDEX SKIP SCAN' FROM plan_table WHERE statement_id = 'C09_6' AND options = 'SKIP SCAN'
UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || '7 · el 80 % de las filas: TABLE ACCESS FULL' FROM plan_table WHERE statement_id = 'C09_7' AND operation = 'TABLE ACCESS' AND options = 'FULL';
ROLLBACK;
EXIT
