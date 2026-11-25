-- C08 · solucionar · contarle al optimizador la correlación: un grupo de columnas (estadística extendida)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
COLUMN extension_name FORMAT A30
SELECT DBMS_STATS.CREATE_EXTENDED_STATS('T6', 'CLIENTE', '(CIUDAD, COMUNIDAD)') AS extension_name FROM dual;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'CLIENTE', method_opt => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS SIZE 1 (CIUDAD, COMUNIDAD)', no_invalidate => FALSE)
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_despues */ c.id_cliente, c.nombre, p.id_pedido, p.importe
  FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente
 WHERE c.ciudad = 'Ciudad0042' AND c.comunidad = 'COM09';
SET TERMOUT ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST +PREDICATE -NOTE'));
EXIT
