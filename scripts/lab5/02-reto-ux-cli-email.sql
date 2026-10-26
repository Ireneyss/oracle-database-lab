-- scripts/lab5/02-reto-ux-cli-email.sql — reto de la Parte C: altura de UX_CLI_EMAIL calculada a mano y comprobada con INDEX_STATS
-- Se ejecuta como SYSDBA: bash scripts/ops/sysdba.sh <este archivo> <evidencia>
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
PROMPT ===== 1. Predicción a mano (30 bytes por entrada de hoja, fo máximo de IX_PED_CLIENTE = 543) =====
DECLARE
  hoja_util CONSTANT NUMBER := 7996; fo CONSTANT NUMBER := 543; r CONSTANT NUMBER := 100000;
  por_hoja NUMBER; hojas NUMBER;
BEGIN
  por_hoja := FLOOR(hoja_util * 0.9 / 30);
  hojas := CEIL(r / por_hoja);
  DBMS_OUTPUT.PUT_LINE('entradas por hoja = floor(7996 x 0,9 / 30) = ' || por_hoja || ' -> hojas = ceil(100000/' || por_hoja || ') = ' || hojas);
  DBMS_OUTPUT.PUT_LINE('altura = 1 + ceil(log_543(' || hojas || ')) = ' || (1 + CEIL(LOG(fo, hojas))));
END;
/
PROMPT ===== 2. Medida: ANALYZE INDEX ... VALIDATE STRUCTURE e INDEX_STATS =====
ANALYZE INDEX tiendasur.ux_cli_email VALIDATE STRUCTURE;
SELECT name, height, lf_rows, lf_blks, br_rows, br_blks, ROUND(lf_rows_len / lf_rows, 1) AS bytes_entrada_hoja,
       ROUND(br_rows_len / NULLIF(br_rows, 0), 1) AS bytes_entrada_rama, pct_used, del_lf_rows
  FROM index_stats;
SELECT 'fo real = (hojas + ramas - 1) / ramas = ' || ROUND((lf_blks + br_blks - 1) / br_blks) ||
       ' | fo máximo = 8028 / bytes por entrada de rama = ' || ROUND(8028 / (br_rows_len / br_rows)) ||
       ' | entradas por hoja = ' || ROUND(lf_rows / lf_blks) AS calculo
  FROM index_stats;
PROMPT ===== 3. El mismo análisis para PK_CLIENTE (mismas 100 000 entradas, clave creciente) =====
ANALYZE INDEX tiendasur.pk_cliente VALIDATE STRUCTURE;
SELECT name, height, lf_rows, lf_blks, br_rows, br_blks, ROUND(lf_rows_len / lf_rows, 1) AS bytes_entrada_hoja,
       ROUND(br_rows_len / NULLIF(br_rows, 0), 1) AS bytes_entrada_rama, pct_used, del_lf_rows
  FROM index_stats;
EXIT
