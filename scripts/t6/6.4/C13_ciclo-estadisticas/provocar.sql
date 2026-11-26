-- C13 · provocar · el cierre de mes pasa a 'E' (enviado) el 15 % de los pedidos completados. Las estadísticas
-- de PEDIDO quedan obsoletas y sin histograma. Hay que recogerlas EN HORARIO DE TIENDA ABIERTA: sin red, no.
-- Efectos: UPDATE de unas 135 000 filas de T6.PEDIDO (observar las devuelve a su estado). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN
  FOR t IN (SELECT 1 FROM dba_tables WHERE owner = 'T6' AND table_name = 'C13_CAMBIO') LOOP
    EXECUTE IMMEDIATE 'UPDATE t6.pedido SET estado = ''C'' WHERE id_pedido IN (SELECT id_pedido FROM t6.c13_cambio)';
    EXECUTE IMMEDIATE 'DROP TABLE t6.c13_cambio PURGE';
  END LOOP;
  DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO', 'PUBLISH', 'TRUE');
  DBMS_STATS.DELETE_PENDING_STATS('T6', 'PEDIDO');
  DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR ALL COLUMNS SIZE 1', no_invalidate => FALSE);
END;
/
CREATE TABLE t6.c13_cambio TABLESPACE tbs_t6 AS SELECT id_pedido FROM t6.pedido WHERE MOD(id_pedido, 100) < 15 AND estado = 'C';
SET ECHO ON
UPDATE t6.pedido SET estado = 'E' WHERE id_pedido IN (SELECT id_pedido FROM t6.c13_cambio);
COMMIT;
EXIT
