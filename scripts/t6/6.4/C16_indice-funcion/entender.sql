-- C16 · entender · la misma búsqueda, escrita «exacta», va por el índice; con UPPER, no
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN consulta FORMAT A46
COLUMN lecturas FORMAT 999999
SET TERMOUT OFF
SELECT /*+ t6_c16_exacta */ MAX(id_cliente) FROM t6.cliente WHERE email = 'cliente997@tiendasur.es';
SET TERMOUT ON
SELECT CASE WHEN sql_text LIKE '%t6_c16_exacta%' THEN 'email = ''cliente997@tiendasur.es'''
            ELSE 'UPPER(email) = UPPER(:correo)' END AS consulta, ROUND(buffer_gets / executions) AS lecturas
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_%' ORDER BY 2;
PROMPT -- Lectura: el índice guarda los correos tal cual. Aplicar una función a la columna impide usarlo: hay que
PROMPT -- leer los 100 000 clientes y calcular UPPER en cada uno.
EXIT
