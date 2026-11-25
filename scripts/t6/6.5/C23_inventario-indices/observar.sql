-- C23 · observar · devolver el banco a su estado (el índice vuelve a VISIBLE) y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
ALTER INDEX t6.ix_t6_ped_cliente VISIBLE;
DROP INDEX t6.ix_c23_cli_fecha;
SELECT index_name, visibility FROM dba_indexes WHERE owner = 'T6' AND table_name = 'PEDIDO' ORDER BY 1;
PROMPT == Lo que debes retener (runbook RB-3) ==
PROMPT 1. Antes de crear: inventario (columnas EN ORDEN), redundancia por prefijo, selectividad real y uso: t6 indices TABLA.
PROMPT 2. Un índice (A) queda cubierto por (A, B) para buscar por A; al revés, no.
PROMPT 3. Retirar con red: INVISIBLE una temporada vigilando DBA_INDEX_USAGE y AWR; borrar después.
PROMPT 4. Cuidado con las FK: la columna hija sin índice inicial provoca bloqueos de tabla al borrar o actualizar el padre.
EXIT
