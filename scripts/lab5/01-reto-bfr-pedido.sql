-- scripts/lab5/01-reto-bfr-pedido.sql — reto de la Parte B: filas reales por bloque de PEDIDO y CLIENTE frente a NUM_ROWS / BLOCKS
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
PROMPT ===== Reto B: bfr medido bloque a bloque (DBMS_ROWID) frente a NUM_ROWS / BLOCKS =====
SELECT 'PEDIDO' AS tabla, COUNT(*) AS bloques_con_filas, MIN(n) AS min_filas, ROUND(AVG(n), 1) AS media_filas, MAX(n) AS max_filas
  FROM (SELECT COUNT(*) AS n FROM tiendasur.pedido GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'));
SELECT 'CLIENTE' AS tabla, COUNT(*) AS bloques_con_filas, MIN(n) AS min_filas, ROUND(AVG(n), 1) AS media_filas, MAX(n) AS max_filas
  FROM (SELECT COUNT(*) AS n FROM tiendasur.cliente GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'));
SELECT table_name, num_rows, blocks, ROUND(num_rows / blocks, 1) AS bfr_estadisticas, pct_free, avg_row_len
  FROM dba_tables WHERE owner = 'TIENDASUR' AND table_name IN ('CLIENTE', 'PEDIDO') ORDER BY table_name;
PROMPT ===== Reparto: cuántos bloques de PEDIDO tienen cada número de filas =====
SELECT n AS filas_en_bloque, COUNT(*) AS bloques FROM
  (SELECT COUNT(*) AS n FROM tiendasur.pedido GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'))
 GROUP BY n ORDER BY n;
PROMPT ===== PCTFREE y longitud real de fila de PEDIDO =====
SELECT pct_free, avg_row_len, blocks, num_rows FROM dba_tables WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO';
SELECT MIN(VSIZE(id_pedido) + VSIZE(id_cliente) + VSIZE(fecha_pedido) + VSIZE(estado) + VSIZE(importe) + VSIZE(canal) + VSIZE(codigo_postal)) AS min_bytes_datos,
       MAX(VSIZE(id_pedido) + VSIZE(id_cliente) + VSIZE(fecha_pedido) + VSIZE(estado) + VSIZE(importe) + VSIZE(canal) + VSIZE(codigo_postal)) AS max_bytes_datos
  FROM tiendasur.pedido;
EXIT
