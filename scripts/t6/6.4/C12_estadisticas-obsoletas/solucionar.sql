-- C12 · solucionar · recoger estadísticas de la tabla que ha cambiado (y solo de esa) y repetir el informe
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
ALTER SESSION SET optimizer_adaptive_plans = FALSE;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'CARRITO', no_invalidate => FALSE)
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_despues */ COUNT(*), SUM(p.importe)
  FROM t6.carrito k JOIN t6.pedido p ON p.id_pedido = k.id_pedido;
SET TERMOUT ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST -NOTE'));
EXIT
