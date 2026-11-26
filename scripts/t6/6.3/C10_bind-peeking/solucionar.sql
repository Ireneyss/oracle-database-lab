-- C10 · solucionar · no se toca nada: se deja trabajar al cursor adaptativo (Adaptive Cursor Sharing).
-- Tras ver ejecuciones con cifras muy distintas, Oracle marca el cursor como CONSCIENTE y crea un hijo nuevo para 'C'.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF FEEDBACK OFF
VARIABLE e VARCHAR2(1)
EXEC :e := 'C'
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC +PEEKED_BINDS +ROWS'));
EXIT
