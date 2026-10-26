-- scripts/lab5/06-reto-v006.sql — reto de la Parte G: defender un índice propio (IX_CLI_TELEFONO para Q5) con las cinco preguntas
-- Se ejecuta como SYSDBA. Crea el índice de prueba, mide lecturas y coste de escritura, y lo BORRA al final:
-- la decisión se versiona aparte (V006 en una rama propia), no se deja en la base por un experimento.
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A18
COLUMN column_name FORMAT A14
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED
DEFINE tel = '661452937'
PROMPT ===== 0. Índices de CLIENTE hoy (tras V005) =====
SELECT i.index_name, LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
 WHERE i.owner = 'TIENDASUR' AND i.table_name = 'CLIENTE' GROUP BY i.index_name ORDER BY 1;
PROMPT ===== 1. NECESIDAD y lecturas antes (Q5: identificar a quien llama por email o teléfono) =====
EXEC lab_tools.medir.consulta('Q5 antes', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']')
EXEC lab_tools.medir.dml('CLIENTE antes: 2000 INSERT', q'[BEGIN FOR i IN 1 .. 2000 LOOP INSERT INTO tiendasur.cliente VALUES (500000 + i, LPAD(500000 + i, 8, '0') || 'Z', 'nuevo' || i || '@tiendasur.es', 'N', 'Apellido Prueba', TO_CHAR(700000000 + i), 'ES', 'Murcia', SYSDATE); END LOOP; END;]', 2000)
PROMPT ===== 2. VIABILIDAD: selectividad de telefono =====
SELECT column_name, num_distinct, ROUND(100 / num_distinct, 4) AS pct_por_valor FROM dba_tab_col_statistics
 WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'TELEFONO';
PROMPT ===== 3. Con el índice propuesto =====
DROP INDEX IF EXISTS tiendasur.ix_cli_telefono;
CREATE INDEX tiendasur.ix_cli_telefono ON tiendasur.cliente (telefono);
EXEC lab_tools.medir.consulta('Q5 con ix_cli_telefono', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']')
EXEC lab_tools.medir.dml('CLIENTE despues: 2000 INSERT', q'[BEGIN FOR i IN 1 .. 2000 LOOP INSERT INTO tiendasur.cliente VALUES (500000 + i, LPAD(500000 + i, 8, '0') || 'Z', 'nuevo' || i || '@tiendasur.es', 'N', 'Apellido Prueba', TO_CHAR(700000000 + i), 'ES', 'Murcia', SYSDATE); END LOOP; END;]', 2000)
SELECT index_name, leaf_blocks AS hojas, ROUND(s.bytes / 1048576, 1) AS mb FROM dba_indexes i
  JOIN dba_segments s ON s.owner = i.owner AND s.segment_name = i.index_name
 WHERE i.owner = 'TIENDASUR' AND i.index_name = 'IX_CLI_TELEFONO';
PROMPT ===== 4. REDUNDANCIA: ¿algún índice de CLIENTE empieza por TELEFONO? =====
SELECT COUNT(*) AS indices_que_empiezan_por_telefono FROM dba_ind_columns
 WHERE index_owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'TELEFONO' AND column_position = 1
   AND index_name <> 'IX_CLI_TELEFONO';
PROMPT ===== 5. Limpieza: el experimento no se queda en la base =====
DROP INDEX tiendasur.ix_cli_telefono;
SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
