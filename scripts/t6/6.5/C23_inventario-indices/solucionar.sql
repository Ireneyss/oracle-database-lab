-- C23 · solucionar · la respuesta a desarrollo: NO se crea índice nuevo; el redundante se retira con red (INVISIBLE)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
PROMPT == 1 · La consulta del historial del cliente ya usa el índice que existe ==
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c23_historial */ id_pedido, fecha_pedido, importe FROM t6.pedido
 WHERE id_cliente = 4242 AND fecha_pedido >= DATE '2026-01-01' ORDER BY fecha_pedido;
SET TERMOUT ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC +PREDICATE'));
PROMPT == 2 · El índice de una sola columna queda cubierto por el compuesto: se hace INVISIBLE (no se borra aún) ==
ALTER INDEX t6.ix_t6_ped_cliente INVISIBLE;
PROMPT == 3 · ¿Sigue la FK protegida? Borrar un cliente necesita un índice que empiece por ID_CLIENTE: lo da el compuesto ==
EXPLAIN PLAN FOR DELETE FROM t6.cliente WHERE id_cliente = -1;
SELECT index_name, visibility FROM dba_indexes WHERE owner = 'T6' AND index_name IN ('IX_T6_PED_CLIENTE', 'IX_C23_CLI_FECHA');
EXIT
