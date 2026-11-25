-- C02 · provocar · la carga de pedidos de la noche: 20 000 ventas, una a una, con COMMIT después de CADA fila
-- Así está escrita la integración con la pasarela de pago («para no perder nada»). Efectos: T6.VENTA_LOG y T6.C02_MEDIDA.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN
  FOR t IN (SELECT table_name FROM dba_tables WHERE owner = 'T6' AND table_name IN ('VENTA_LOG', 'C02_MEDIDA')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE t6.' || t.table_name || ' PURGE'; END LOOP;
END;
/
CREATE TABLE t6.venta_log (etq VARCHAR2(12), id_pedido NUMBER, importe NUMBER, ts TIMESTAMP DEFAULT SYSTIMESTAMP) TABLESPACE tbs_t6;
CREATE TABLE t6.c02_medida (etq VARCHAR2(12), filas_por_commit NUMBER, ms_total NUMBER, commits NUMBER, redo_bytes NUMBER,
                            cpu_ms NUMBER, esperas_lfs NUMBER, ms_lfs NUMBER) TABLESPACE tbs_t6;
PROMPT == Cargando 20 000 ventas con COMMIT por fila ... ==
@@_medir 1 POR_FILA
SELECT etq, ms_total, ROUND(20000 / (ms_total / 1000)) AS filas_seg FROM t6.c02_medida WHERE etq = 'POR_FILA';
EXIT
