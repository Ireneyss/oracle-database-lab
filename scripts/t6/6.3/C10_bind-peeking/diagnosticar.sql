-- C10 · diagnosticar · ¿es sensible al valor? Las marcas del cursor (bind sensitive / bind aware)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN sensible FORMAT A8
COLUMN consciente FORMAT A10
SELECT child_number, plan_hash_value, executions, ROUND(buffer_gets / executions) AS gets_ejec,
       is_bind_sensitive AS sensible, is_bind_aware AS consciente, is_shareable AS compartible
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c10 */%' ORDER BY child_number;
SELECT column_name, num_distinct, histogram FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'PEDIDO' AND column_name = 'ESTADO';
PROMPT -- Lectura: SENSIBLE = Y porque hay histograma: Oracle vigila si el valor cambia el número de filas.
EXIT
