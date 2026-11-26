-- C14 · provocar · el panel «Pendientes del teléfono» del call center: pedidos en estado P del canal T desde enero
-- Se abre 30 veces por hora. Devuelve unos 2 000 pedidos de un millón, pero tarda y consume como un informe.
-- Efectos: ninguno en datos (solo cursores en la shared pool). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
BEGIN FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_C14_PEND') LOOP
  EXECUTE IMMEDIATE 'DROP INDEX t6.ix_t6_c14_pend'; END LOOP; END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
PROMPT == El call center abre el panel 30 veces ==
DECLARE n NUMBER; s NUMBER;
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('call_center', 'C14_PANEL');
  FOR i IN 1 .. 30 LOOP
    SELECT /*+ t6_c14_panel */ COUNT(*), SUM(importe) INTO n, s FROM t6.pedido
     WHERE estado = 'P' AND canal = 'T' AND fecha_pedido >= DATE '2026-01-01';
  END LOOP;
END;
/
SELECT 'Panel abierto ' || executions || ' veces: ' || ROUND(elapsed_time / executions / 1000, 1) || ' ms y '
       || ROUND(buffer_gets / executions) || ' lecturas lógicas por apertura' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel */%';
EXIT
