-- C05 · observar · la otra cara: con POCAS filas de entrada (los 100 clientes de Lorca) los bucles anidados ganan
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED LINESIZE 200
EXEC lab_tools.medir.consulta('Lorca, elige Oracle', q'[SELECT c.id_cliente, p.id_pedido, p.importe FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.ciudad = 'Lorca']')
EXEC lab_tools.medir.consulta('Lorca, HASH forzado', q'[SELECT /*+ LEADING(c p) USE_HASH(p) FULL(p) */ c.id_cliente, p.id_pedido, p.importe FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.ciudad = 'Lorca']')
PROMPT == Lo que debes retener ==
PROMPT 1. NESTED LOOPS: pocas filas de entrada y un índice en la tabla interna. HASH JOIN: muchas filas, se lee una vez cada tabla.
PROMPT 2. El método lo decide la CARDINALIDAD: una sugerencia copiada de otra consulta congela una decisión que no es suya.
PROMPT 3. En el plan real, Starts × filas de la parte interna explica de dónde salen las lecturas.
EXIT
