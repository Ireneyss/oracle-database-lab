-- C16 · observar · la columna virtual oculta que crea el índice, y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN column_name FORMAT A14
COLUMN data_default FORMAT A20
SELECT c.column_name, c.hidden_column, c.virtual_column, c.num_distinct
  FROM dba_tab_cols c
 WHERE c.owner = 'T6' AND c.table_name = 'CLIENTE' AND (c.column_name LIKE 'SYS_NC%' OR c.column_name = 'EMAIL');
PROMPT == Lo que debes retener ==
PROMPT 1. Una función sobre la columna (UPPER, TRUNC, TO_CHAR, NVL...) anula el índice normal de esa columna.
PROMPT 2. El índice basado en función indexa la EXPRESIÓN; la consulta debe escribirla igual: UPPER(email).
PROMPT 3. Oracle crea una columna virtual oculta (SYS_NC...): recoge sus estadísticas (FOR ALL HIDDEN COLUMNS).
PROMPT 4. Variante de examen: TRUNC(fecha_pedido) = DATE '2026-11-01' tampoco usa IX_T6_PED_FECHA. Mejor que un índice
PROMPT    nuevo: reescribir como rango, fecha_pedido >= DATE '2026-11-01' AND fecha_pedido < DATE '2026-11-02'.
PROMPT 5. Pariente de C07: allí la función la ponía Oracle (TO_NUMBER implícito); aquí la escribe la aplicación.
EXIT
