-- C10 · entender · llega 'C' (el 90 % de los pedidos): la misma sentencia, con el plan que se eligió para 'P'
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF
VARIABLE e VARCHAR2(1)
EXEC :e := 'C'
SELECT /* t6_c10 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE estado = :e;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'BASIC +PEEKED_BINDS +ROWS'));
SET ECHO OFF
SELECT child_number, plan_hash_value, executions, ROUND(buffer_gets / executions) AS gets_ejec
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c10 */%' ORDER BY child_number;
PROMPT -- Lectura: el plan se eligió MIRANDO el primer valor ('P', bind peeking) y se reutiliza para 'C'.
EXIT
