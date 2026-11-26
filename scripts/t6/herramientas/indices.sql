-- =====================================================================================================
-- herramientas/indices.sql · inventario de índices de una tabla antes de crear otro (runbook RB-3)
-- Uso: t6 indices TABLA [esquema]        esquema por defecto: T6
-- Muestra: (1) cada índice con sus columnas, estado, visibilidad y factor de agrupamiento frente a bloques y filas;
--   (2) índices REDUNDANTES (sus columnas son el prefijo de otro); (3) uso registrado (DBA_INDEX_USAGE, por muestreo,
--   se vuelca cada ~15 min y no cuenta las consultas de SYS); (4) selectividad de las columnas candidatas.
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN columnas FORMAT A30
COLUMN visibility FORMAT A9 HEADING VISIBLE
COLUMN cf_vs FORMAT A12 HEADING "CF PARECE"
COLUMN redundante FORMAT A20
COLUMN cubierto_por FORMAT A20
PROMPT == 1 · Índices de &2..&1 ==
SELECT i.index_name, (SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_position) FROM dba_ind_columns c
                       WHERE c.index_owner = i.owner AND c.index_name = i.index_name) AS columnas,
       i.status, i.visibility, i.leaf_blocks, i.distinct_keys, i.clustering_factor,
       CASE WHEN i.clustering_factor <= t.blocks * 2 THEN 'A BLOQUES' WHEN i.clustering_factor >= t.num_rows * 0.5 THEN 'A FILAS' ELSE 'INTERMEDIO' END AS cf_vs
  FROM dba_indexes i JOIN dba_tables t ON t.owner = i.table_owner AND t.table_name = i.table_name
 WHERE i.table_owner = UPPER('&2') AND i.table_name = UPPER('&1') ORDER BY i.index_name;
PROMPT == 2 · Redundancia: índices cuyas columnas son el principio de otro índice ==
WITH c AS (SELECT index_name, LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position) AS cols
             FROM dba_ind_columns WHERE table_owner = UPPER('&2') AND table_name = UPPER('&1') GROUP BY index_name)
SELECT a.index_name AS redundante, a.cols AS columnas, b.index_name AS cubierto_por
  FROM c a JOIN c b ON a.index_name <> b.index_name AND b.cols LIKE a.cols || ',%';
PROMPT == 3 · Uso registrado (DBA_INDEX_USAGE) ==
SELECT u.name AS index_name, u.total_access_count AS accesos, u.total_exec_count AS ejecuciones, u.last_used
  FROM dba_index_usage u WHERE u.owner = UPPER('&2')
   AND u.name IN (SELECT index_name FROM dba_indexes WHERE table_owner = UPPER('&2') AND table_name = UPPER('&1'))
 ORDER BY u.name;
PROMPT == 4 · Selectividad de cada columna (1/distintos) ==
SELECT column_name, num_distinct, ROUND(100 / NULLIF(num_distinct, 0), 4) AS pct_por_valor, histogram
  FROM dba_tab_col_statistics WHERE owner = UPPER('&2') AND table_name = UPPER('&1') ORDER BY num_distinct DESC;
EXIT
