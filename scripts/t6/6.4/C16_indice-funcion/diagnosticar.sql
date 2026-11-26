-- C16 · diagnosticar · el predicado dice la causa: filter(UPPER("EMAIL")=...) sobre un TABLE ACCESS FULL
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 170
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login */%' AND ROWNUM = 1), NULL, 'TYPICAL -NOTE -HINT_REPORT'));
COLUMN column_expression FORMAT A30
SELECT i.index_name, c.column_name, e.column_expression
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
  LEFT JOIN dba_ind_expressions e ON e.index_owner = i.owner AND e.index_name = i.index_name
 WHERE i.owner = 'T6' AND i.table_name = 'CLIENTE' ORDER BY 1;
PROMPT -- Lectura: hay índice sobre EMAIL, ninguno sobre la EXPRESIÓN UPPER(EMAIL). La solución es indexar la expresión.
EXIT
