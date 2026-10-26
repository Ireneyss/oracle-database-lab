-- scripts/lab5/03-reto-cubriente-q9.sql — reto de la Parte D: ¿merece la pena hacer cubriente IX_PED_FECHA para Q9?
-- Se ejecuta como SYSDBA. Crea un índice de prueba, lo mide y lo BORRA al final (el banco queda como estaba).
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
COLUMN index_name FORMAT A22
PROMPT ===== 1. Q9 hoy (IX_PED_FECHA) =====
EXEC lab_tools.medir.consulta('Q9 actual', q'[SELECT * FROM tiendasur.pedido ORDER BY fecha_pedido DESC FETCH FIRST 20 ROWS ONLY]')
PROMPT ===== 2. Q9 con un índice cubriente de prueba (fecha + todas las columnas) =====
DROP INDEX IF EXISTS tiendasur.ix_reto_q9_cub;
CREATE INDEX tiendasur.ix_reto_q9_cub ON tiendasur.pedido (fecha_pedido, id_pedido, id_cliente, estado, importe, canal, codigo_postal);
EXEC lab_tools.medir.consulta('Q9 cubriente', q'[SELECT * FROM tiendasur.pedido ORDER BY fecha_pedido DESC FETCH FIRST 20 ROWS ONLY]')
PROMPT ===== 3. Lo que ocuparía frente a la tabla =====
SELECT segment_name AS index_name, ROUND(bytes / 1048576, 1) AS mb FROM dba_segments
 WHERE owner = 'TIENDASUR' AND segment_name IN ('PEDIDO', 'IX_PED_FECHA', 'IX_RETO_Q9_CUB') ORDER BY bytes DESC;
PROMPT ===== 4. Limpieza =====
DROP INDEX tiendasur.ix_reto_q9_cub;
SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
