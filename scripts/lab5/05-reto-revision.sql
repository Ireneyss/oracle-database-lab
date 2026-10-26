-- scripts/lab5/05-reto-revision.sql — reto de la Parte F: revisión de código de una consulta del panel de atención al cliente
-- Se ejecuta como SYSDBA. Crea dos índices temporales, mide la consulta rota y la reescrita, y los BORRA al final.
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
PROMPT ===== 0. Los datos: cómo se guardan teléfono y apellidos =====
SELECT telefono, apellidos FROM tiendasur.cliente WHERE id_cliente <= 3 ORDER BY id_cliente;
SELECT COUNT(*) AS upper_apellidos_gil FROM tiendasur.cliente WHERE UPPER(apellidos) = 'GIL';
SELECT COUNT(*) AS primer_apellido_gil FROM tiendasur.cliente WHERE apellidos LIKE 'Gil %';
SELECT COUNT(*) AS telefono_600 FROM tiendasur.cliente WHERE telefono LIKE '600%';
PROMPT ===== 1. Índices temporales para la prueba (no existen en el banco) =====
DROP INDEX IF EXISTS tiendasur.ix_rev_telefono;
DROP INDEX IF EXISTS tiendasur.ix_rev_apellidos;
CREATE INDEX tiendasur.ix_rev_telefono ON tiendasur.cliente (telefono);
CREATE INDEX tiendasur.ix_rev_apellidos ON tiendasur.cliente (apellidos);
PROMPT ===== 2. Antes y después =====
EXEC lab_tools.medir.consulta('PR original', q'[SELECT * FROM tiendasur.cliente WHERE SUBSTR(telefono, 1, 3) = '600' OR UPPER(apellidos) = 'GIL']')
EXEC lab_tools.medir.consulta('PR reescrita OR', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' OR apellidos LIKE 'Gil %']')
EXEC lab_tools.medir.consulta('PR reescrita UNION', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' UNION SELECT * FROM tiendasur.cliente WHERE apellidos LIKE 'Gil %']')
EXEC lab_tools.medir.consulta('PR solo telefono', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%']')
PROMPT ===== 3. Limpieza =====
DROP INDEX tiendasur.ix_rev_telefono;
DROP INDEX tiendasur.ix_rev_apellidos;
SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
