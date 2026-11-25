-- C07 · observar · el mismo defecto con fechas: comparar una DATE con SYSTIMESTAMP convierte la columna
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
EXPLAIN PLAN FOR SELECT * FROM t6.pedido WHERE fecha_pedido >= SYSTIMESTAMP - INTERVAL '1' DAY;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +ROWS +PREDICATE'));
EXPLAIN PLAN FOR SELECT * FROM t6.pedido WHERE fecha_pedido >= SYSDATE - 1;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +ROWS +PREDICATE'));
PROMPT == Lo que debes retener ==
PROMPT 1. EXPLAIN PLAN predice (no ejecuta, no conoce el tipo ni el valor de la variable). DISPLAY_CURSOR cuenta lo que pasó.
PROMPT 2. Un TO_NUMBER, TO_CHAR o INTERNAL_FUNCTION sobre la COLUMNA en «Predicate Information» = el índice no sirve.
PROMPT 3. La cura es el tipo correcto en la aplicación (un solo cambio). Un índice basado en función sería tapar el defecto.
PROMPT 4. Con la herramienta del kit: t6 top 5 elapsed t6_cp  →  t6 plan SQL_ID   (playbook PB-2).
EXIT
