-- C08 · observar · dónde vive la extensión, cómo se llama y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN column_name FORMAT A32
SELECT extension_name, extension, creator, droppable FROM dba_stat_extensions WHERE owner = 'T6' AND table_name = 'CLIENTE';
SELECT column_name, num_distinct, histogram FROM dba_tab_col_statistics WHERE owner = 'T6' AND table_name = 'CLIENTE' AND column_name LIKE 'SYS_ST%';
PROMPT == Lo que debes retener ==
PROMPT 1. Técnica maestra: E-Rows × Starts frente a A-Rows, de dentro afuera. La primera línea que se desvía es la causa.
PROMPT 2. Columnas correlacionadas: el optimizador multiplica selectividades y SUBESTIMA. Cura: grupo de columnas.
PROMPT 3. El grupo de columnas es una columna virtual oculta (SYS_STU...): cuenta las COMBINACIONES distintas.
PROMPT 4. Variante de examen: DBMS_STATS.SEED_COL_USAGE + REPORT_COL_USAGE descubren qué grupos crear.
EXIT
