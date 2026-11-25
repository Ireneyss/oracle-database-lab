-- INC-605 · romper · tabla de cestas abandonadas analizada con 100 filas y estadísticas BLOQUEADAS; la carga mete muchas más
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN n NEW_VALUE filas
SELECT TO_CHAR(150000 + &1 * 1000) AS n FROM dual;
BEGIN FOR t IN (SELECT 1 FROM dba_tables WHERE owner = 'T6' AND table_name = 'CESTA') LOOP EXECUTE IMMEDIATE 'DROP TABLE t6.cesta PURGE'; END LOOP; END;
/
CREATE TABLE t6.cesta (id_pedido NUMBER, id_cliente NUMBER, ts DATE) TABLESPACE tbs_t6;
INSERT INTO t6.cesta SELECT id_pedido, id_cliente, SYSDATE FROM t6.pedido WHERE id_pedido <= 100;
COMMIT;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'CESTA')
EXEC DBMS_STATS.LOCK_TABLE_STATS('T6', 'CESTA')
INSERT INTO t6.cesta SELECT id_pedido, id_cliente, SYSDATE FROM t6.pedido WHERE id_pedido BETWEEN 400001 AND 400000 + &filas;
COMMIT;
@@../_registro INC-605 &1 &2 "cesta con &filas filas nuevas"
SET TERMOUT ON
PROMPT Roto: el informe de cestas abandonadas (módulo informes) ya no es el de ayer.
EXIT
