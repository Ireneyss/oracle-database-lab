-- C12 · provocar · la tabla de trabajo CARRITO: se analizó vacía (100 filas) y la carga nocturna mete 200 000.
-- Nadie recogió estadísticas al terminar la carga. A primera hora, el informe de conversión cruza CARRITO con PEDIDO.
-- Efectos: tabla T6.CARRITO (observar no la borra; caso --preparar sí). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
BEGIN FOR t IN (SELECT 1 FROM dba_tables WHERE owner = 'T6' AND table_name = 'CARRITO') LOOP
  EXECUTE IMMEDIATE 'DROP TABLE t6.carrito PURGE'; END LOOP; END;
/
CREATE TABLE t6.carrito (id_pedido NUMBER, id_cliente NUMBER, ts DATE) TABLESPACE tbs_t6;
INSERT INTO t6.carrito SELECT id_pedido, id_cliente, SYSDATE FROM t6.pedido WHERE id_pedido <= 100;
COMMIT;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'CARRITO')
PROMPT == La carga nocturna: 200 000 líneas de carrito más (sin recoger estadísticas al final) ==
INSERT INTO t6.carrito SELECT id_pedido, id_cliente, SYSDATE FROM t6.pedido WHERE id_pedido BETWEEN 300001 AND 500000;
COMMIT;
PROMPT == A primera hora: el informe de conversión ==
PROMPT   (la herramienta de informes abre su sesión con optimizer_adaptive_plans = FALSE, como pide su proveedor)
ALTER SESSION SET optimizer_adaptive_plans = FALSE;
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_antes */ COUNT(*), SUM(p.importe)
  FROM t6.carrito k JOIN t6.pedido p ON p.id_pedido = k.id_pedido;
SET TERMOUT ON
SELECT 'Informe ejecutado en ' || ROUND(elapsed_time / 1000) || ' ms con ' || buffer_gets || ' lecturas lógicas' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS t6_c12_antes%';
EXIT
