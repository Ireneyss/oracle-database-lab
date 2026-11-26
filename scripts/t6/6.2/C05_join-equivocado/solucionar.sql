-- C05 · solucionar · quitar la sugerencia y dejar decidir al optimizador (con estadísticas correctas elige HASH JOIN)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c05_ok */ c.id_cliente, SUM(p.importe) AS total
  FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.pais = 'ES' GROUP BY c.id_cliente;
SET TERMOUT ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST -NOTE'));
EXIT
