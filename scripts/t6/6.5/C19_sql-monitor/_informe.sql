-- C19 · _informe · el informe de fidelización (ventana analítica + join + agrupación) con la etiqueta &1
SET TERMOUT OFF
SELECT /*+ MONITOR */ /* t6_c19_&1 */ c.comunidad, p.canal, COUNT(DISTINCT p.id_cliente) AS clientes, SUM(p.importe) AS importe,
       MAX(p.n_pedido) AS max_pedidos_cliente
  FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.id_cliente ORDER BY x.fecha_pedido) AS n_pedido FROM t6.pedido x) p
  JOIN t6.cliente c ON c.id_cliente = p.id_cliente
 GROUP BY c.comunidad, p.canal ORDER BY importe DESC;
SET TERMOUT ON
