-- C10 · provocar · el contador de pedidos por estado de la web, con variable de enlace. Primero llega 'P' (2 %).
-- Efectos: histograma en T6.PEDIDO.ESTADO (observar lo retira). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR COLUMNS estado SIZE 254', no_invalidate => FALSE)
ALTER SYSTEM FLUSH SHARED_POOL;
VARIABLE e VARCHAR2(1)
EXEC :e := 'P'
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC +PEEKED_BINDS +ROWS'));
EXIT
