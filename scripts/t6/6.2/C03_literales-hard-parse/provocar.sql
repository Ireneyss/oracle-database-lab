-- C03 · provocar · la ficha de cliente de la web: 5 000 consultas en las que la aplicación PEGA el id en el texto
-- La versión en producción (T6.APP.FICHA_LITERAL) concatena: '... WHERE id_cliente = ' || p_id. Efectos: T6.C03_MEDIDA.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN FOR t IN (SELECT 1 FROM dba_tables WHERE owner = 'T6' AND table_name = 'C03_MEDIDA') LOOP
  EXECUTE IMMEDIATE 'DROP TABLE t6.c03_medida PURGE'; END LOOP; END;
/
CREATE TABLE t6.c03_medida (modo VARCHAR2(8), llamadas NUMBER, ms_total NUMBER, cpu_ms NUMBER, ms_analisis NUMBER, hard_parses NUMBER, cursores NUMBER) TABLESPACE tbs_t6;
ALTER SYSTEM FLUSH SHARED_POOL;
PROMPT == 5 000 fichas de cliente con la versión de producción (literales) ... ==
@@_medir LITERAL
SELECT modo, llamadas, ms_total, ROUND(ms_total / llamadas, 2) AS ms_por_ficha FROM t6.c03_medida;
EXIT
