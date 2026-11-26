-- C11 · provocar · los pedidos de los clientes de Lorca: el optimizador no está seguro de cuántos clientes habrá
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
ALTER SYSTEM FLUSH SHARED_POOL;
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c11 */ c.id_cliente, p.id_pedido, p.importe
  FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.ciudad = 'Lorca';
SET TERMOUT ON
SELECT 'Ejecutado: ' || rows_processed || ' filas' AS resultado FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c11%';
EXIT
