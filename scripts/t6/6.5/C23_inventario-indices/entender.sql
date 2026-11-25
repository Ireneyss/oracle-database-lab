-- C23 · entender · la petición: ¿hace falta el índice (id_cliente, fecha_pedido)? Primero, ¿ya existe algo así?
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN columnas FORMAT A34
SELECT i.index_name, LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
 WHERE i.owner = 'T6' AND i.table_name = 'PEDIDO' GROUP BY i.index_name ORDER BY 2;
PROMPT -- Lectura: IX_C23_CLI_FECHA ya cubre (id_cliente, fecha_pedido), y empieza por ID_CLIENTE igual que IX_T6_PED_CLIENTE.
PROMPT -- Crear otro sería el tercero sobre la misma columna inicial. La respuesta a desarrollo empieza por el inventario.
EXIT
