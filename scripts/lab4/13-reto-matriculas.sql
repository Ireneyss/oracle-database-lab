-- scripts/lab4/13-reto-matriculas.sql — reto de la Parte L: dimensionar ACA_MATRICULAS con la fórmula y comparar con lo real
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
PROMPT ===== 1. Predicción (Unidad 3) frente a estadísticas =====
EXEC DBMS_STATS.GATHER_TABLE_STATS('ADMIN_ACADEMIA', 'ACA_MATRICULAS')
SELECT t.num_rows AS r, t.avg_row_len AS r_bytes, t.pct_free, t.blocks AS bloques_bajo_hwm, s.blocks AS bloques_asignados,
       FLOOR((8192 - 96) * (1 - t.pct_free / 100) / t.avg_row_len) AS bfr_u3,
       CEIL(t.num_rows / FLOOR((8192 - 96) * (1 - t.pct_free / 100) / t.avg_row_len)) AS b_predicho,
       ROUND(t.num_rows / t.blocks, 1) AS bfr_real,
       ROUND(t.blocks * 8192 / (150 * 1048576) * 1000, 1) AS ms_full_hdd_150mbs
  FROM dba_tables t JOIN dba_segments s ON s.owner = t.owner AND s.segment_name = t.table_name
 WHERE t.owner = 'ADMIN_ACADEMIA' AND t.table_name = 'ACA_MATRICULAS';
PROMPT ===== 2. Filas reales por bloque (DBMS_ROWID) =====
SELECT COUNT(*) AS bloques_con_filas, MIN(n) AS min_filas, ROUND(AVG(n), 1) AS media_filas, MAX(n) AS max_filas
  FROM (SELECT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') AS blk, COUNT(*) AS n
          FROM admin_academia.aca_matriculas GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'));
PROMPT ===== 3. Llenado de los bloques (DBMS_SPACE.SPACE_USAGE) =====
DECLARE
  unf NUMBER; unfb NUMBER; fs1 NUMBER; fs1b NUMBER; fs2 NUMBER; fs2b NUMBER;
  fs3 NUMBER; fs3b NUMBER; fs4 NUMBER; fs4b NUMBER; llenos NUMBER; llenosb NUMBER;
BEGIN
  DBMS_SPACE.SPACE_USAGE('ADMIN_ACADEMIA', 'ACA_MATRICULAS', 'TABLE', unf, unfb, fs1, fs1b, fs2, fs2b,
                         fs3, fs3b, fs4, fs4b, llenos, llenosb);
  DBMS_OUTPUT.PUT_LINE('FULL=' || llenos || ' FS1=' || fs1 || ' FS2=' || fs2 || ' FS3=' || fs3 || ' FS4=' || fs4 || ' sin formatear=' || unf);
END;
/
PROMPT ===== 4. Columnas: tamaño medio real (la fila incluye cabecera y bytes de longitud) =====
COLUMN column_name FORMAT A22
SELECT column_name, data_type, avg_col_len, nullable FROM dba_tab_columns
 WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_MATRICULAS' ORDER BY column_id;
SELECT ini_trans, max_trans FROM dba_tables WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_MATRICULAS';
EXIT
