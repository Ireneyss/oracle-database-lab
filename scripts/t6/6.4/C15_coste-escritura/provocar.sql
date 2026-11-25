-- C15 · provocar · la tabla de carga diaria de pedidos tiene SEIS índices «por si acaso» (uno por cada petición de informes)
-- Efectos: tablas T6.C15_CARGA y T6.C15_MEDIDA. Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN FOR t IN (SELECT table_name FROM dba_tables WHERE owner = 'T6' AND table_name IN ('C15_CARGA', 'C15_MEDIDA')) LOOP
  EXECUTE IMMEDIATE 'DROP TABLE t6.' || t.table_name || ' PURGE'; END LOOP; END;
/
CREATE TABLE t6.c15_carga TABLESPACE tbs_t6 AS SELECT * FROM t6.pedido WHERE 1 = 0;
CREATE TABLE t6.c15_medida (etq VARCHAR2(14), indices NUMBER, ms NUMBER, redo_mb NUMBER) TABLESPACE tbs_t6;
PROMPT == Carga de 100 000 pedidos SIN índices (la referencia) ==
@@_medir SIN_INDICES
PROMPT == Los seis índices que se fueron añadiendo con los años ==
CREATE INDEX t6.ix_c15_1 ON t6.c15_carga (id_pedido) TABLESPACE tbs_t6;
CREATE INDEX t6.ix_c15_2 ON t6.c15_carga (id_cliente) TABLESPACE tbs_t6;
CREATE INDEX t6.ix_c15_3 ON t6.c15_carga (fecha_pedido) TABLESPACE tbs_t6;
CREATE INDEX t6.ix_c15_4 ON t6.c15_carga (estado, fecha_pedido) TABLESPACE tbs_t6;
CREATE INDEX t6.ix_c15_5 ON t6.c15_carga (estado) TABLESPACE tbs_t6;
CREATE INDEX t6.ix_c15_6 ON t6.c15_carga (codigo_postal, importe) TABLESPACE tbs_t6;
PROMPT == La carga de cada noche, con los seis ==
@@_medir SEIS_INDICES
EXIT
