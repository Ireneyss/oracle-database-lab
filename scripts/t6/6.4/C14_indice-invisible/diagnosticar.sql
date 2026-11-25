-- C14 · diagnosticar · el plan real del panel y el inventario de índices de PEDIDO: ¿falta un índice o sobra uno?
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 170
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel */%' AND ROWNUM = 1), NULL, 'TYPICAL -NOTE -HINT_REPORT'));
COLUMN index_name FORMAT A20
COLUMN columnas FORMAT A40
SELECT i.index_name, LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas, i.distinct_keys
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
 WHERE i.owner = 'T6' AND i.table_name = 'PEDIDO' GROUP BY i.index_name, i.distinct_keys ORDER BY 1;
COLUMN column_name FORMAT A14
SELECT column_name, num_distinct, histogram FROM dba_tab_col_statistics
 WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name IN ('ESTADO', 'CANAL', 'FECHA_PEDIDO');
PROMPT -- Lectura: TABLE ACCESS FULL con los tres filtros. El índice de ESTADO existe, pero solo con 4 valores y sin
PROMPT -- histograma el optimizador estima 250 000 filas en P y lo descarta. Ningún índice combina estado, canal y fecha.
PROMPT -- Propuesta: un índice (estado, canal, fecha_pedido). Primero las igualdades, el rango al final.
PROMPT -- Fíjate también en E-Rows (unas 25 000) frente a las 2 056 reales: sin histograma, la estimación es una media.
EXIT
