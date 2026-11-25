-- C08 · provocar · el listado de pedidos de los clientes de una ciudad y su comunidad (Ciudad0042, COM09)
-- CIUDAD y COMUNIDAD están correlacionadas (cada ciudad está en una sola comunidad), pero el optimizador no lo sabe.
-- Efectos: estadísticas de T6.CLIENTE sin histogramas ni grupos de columnas (el punto de partida). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
BEGIN
  FOR e IN (SELECT extension FROM dba_stat_extensions WHERE owner = 'T6' AND table_name = 'CLIENTE' AND creator = 'USER') LOOP
    DBMS_STATS.DROP_EXTENDED_STATS('T6', 'CLIENTE', e.extension); END LOOP;
  DBMS_STATS.GATHER_TABLE_STATS('T6', 'CLIENTE', method_opt => 'FOR ALL COLUMNS SIZE 1', no_invalidate => FALSE);
END;
/
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_antes */ c.id_cliente, c.nombre, p.id_pedido, p.importe
  FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente
 WHERE c.ciudad = 'Ciudad0042' AND c.comunidad = 'COM09';
SET TERMOUT ON
SELECT 'Listado ejecutado: ' || rows_processed || ' filas' AS resultado FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c08_antes%';
EXIT
