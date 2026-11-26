-- C07 · entender · el síntoma que ve la web: cada búsqueda por código postal tarda decenas de milisegundos
-- y el equipo de desarrollo jura que «hay índice, lo hemos comprobado con EXPLAIN PLAN»
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN ms_p50 FORMAT 9990.0
COLUMN ms_p95 FORMAT 9990.0
SELECT etq, COUNT(*) AS busquedas, ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms), 1) AS ms_p50,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms), 1) AS ms_p95
  FROM t6.app_log WHERE etq LIKE 'C07%' GROUP BY etq ORDER BY etq;
PROMPT == Lo que enseña desarrollo: EXPLAIN PLAN de «la misma» consulta, con una variable ==
SET SERVEROUTPUT OFF
VARIABLE cp NUMBER
EXEC :cp := 30001
EXPLAIN PLAN FOR SELECT COUNT(*), SUM(importe) FROM t6.pedido WHERE codigo_postal = :cp;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +ROWS +COST +PREDICATE'));
PROMPT -- Lectura: EXPLAIN PLAN no ejecuta ni mira el TIPO de la variable (la trata como texto): predice el índice.
EXIT
