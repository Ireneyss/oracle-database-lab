-- C15 · solucionar · quitar el índice redundante y, para la carga masiva, marcar los demás UNUSABLE y reconstruir después
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == 1 · Fuera el redundante (IX_C15_5 = prefijo de IX_C15_4) ==
DROP INDEX t6.ix_c15_5;
@@_medir CINCO_INDICES
PROMPT == 2 · Carga masiva: índices UNUSABLE durante la carga y REBUILD al final (skip_unusable_indexes = TRUE) ==
SET SERVEROUTPUT ON
DECLARE t0 NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE t6.c15_carga';
  t0 := DBMS_UTILITY.GET_TIME;
  FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'T6' AND table_name = 'C15_CARGA') LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX t6.' || i.index_name || ' UNUSABLE'; END LOOP;
  INSERT INTO t6.c15_carga SELECT * FROM t6.pedido WHERE id_pedido <= 100000;
  COMMIT;
  FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'T6' AND table_name = 'C15_CARGA') LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX t6.' || i.index_name || ' REBUILD'; END LOOP;
  INSERT INTO t6.c15_medida VALUES ('UNUSABLE+RB', 5, (DBMS_UTILITY.GET_TIME - t0) * 10, NULL);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('UNUSABLE+RB  índices=5   ' || (DBMS_UTILITY.GET_TIME - t0) * 10 || ' ms (carga + reconstrucción)');
END;
/
EXIT
