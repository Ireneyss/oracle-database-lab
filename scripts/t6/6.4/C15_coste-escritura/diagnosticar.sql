-- C15 · diagnosticar · ¿qué índices sobran? Redundancia (prefijos) y tamaño de cada uno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'C15_CARGA', cascade => TRUE)
COLUMN index_name FORMAT A10
COLUMN columnas FORMAT A28
COLUMN comentario FORMAT A60
SELECT i.index_name, LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas, i.leaf_blocks,
       CASE i.index_name WHEN 'IX_C15_5' THEN 'REDUNDANTE: ESTADO es el prefijo de IX_C15_4'
                         WHEN 'IX_C15_1' THEN 'Clave del pedido: en la tabla real ya la cubre la PK' ELSE '-' END AS comentario
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
 WHERE i.owner = 'T6' AND i.table_name = 'C15_CARGA' GROUP BY i.index_name, i.leaf_blocks ORDER BY 1;
PROMPT -- La herramienta del kit lo hace sola para cualquier tabla:   t6 indices C15_CARGA
EXIT
