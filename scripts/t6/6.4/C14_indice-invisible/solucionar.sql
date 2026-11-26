-- C14 · solucionar · crear el índice INVISIBLE, probarlo en una sola sesión, publicarlo y medir de nuevo
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
CREATE INDEX t6.ix_t6_c14_pend ON t6.pedido (estado, canal, fecha_pedido) INVISIBLE ONLINE TABLESPACE tbs_t6;
SELECT index_name, visibility, status, leaf_blocks FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_C14_PEND';
PROMPT == 1 · Invisible: el resto de sesiones (y esta) siguen igual ==
EXPLAIN PLAN FOR SELECT COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = 'P' AND canal = 'T' AND fecha_pedido >= DATE '2026-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC'));
PROMPT == 2 · Solo esta sesión lo ve: lo probamos con la consulta real ==
ALTER SESSION SET optimizer_use_invisible_indexes = TRUE;
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS t6_c14_prueba */ COUNT(*), SUM(importe) FROM t6.pedido
 WHERE estado = 'P' AND canal = 'T' AND fecha_pedido >= DATE '2026-01-01';
SET TERMOUT ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ALLSTATS LAST -NOTE'));
ALTER SESSION SET optimizer_use_invisible_indexes = FALSE;
PROMPT == 3 · La prueba convence: se publica para todos ==
ALTER INDEX t6.ix_t6_c14_pend VISIBLE;
SET ECHO OFF
DECLARE n NUMBER; s NUMBER;
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('call_center', 'C14_PANEL');
  FOR i IN 1 .. 30 LOOP
    SELECT /*+ t6_c14_panel_v2 */ COUNT(*), SUM(importe) INTO n, s FROM t6.pedido
     WHERE estado = 'P' AND canal = 'T' AND fecha_pedido >= DATE '2026-01-01';
  END LOOP;
END;
/
SELECT 'Panel con el índice: ' || ROUND(elapsed_time / executions / 1000, 2) || ' ms y '
       || ROUND(buffer_gets / executions) || ' lecturas lógicas por apertura' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel_v2 */%';
EXIT
