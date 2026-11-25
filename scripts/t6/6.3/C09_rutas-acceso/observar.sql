-- C09 · observar · limpieza del índice del caso y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
DROP INDEX IF EXISTS t6.ix_t6_ped_canal_imp;
SET ECHO OFF
PROMPT == Lo que debes retener ==
PROMPT 1. FULL: sin filtro útil o con muchas filas. UNIQUE SCAN: igualdad en clave única. RANGE SCAN: rango o no única.
PROMPT 2. FULL SCAN (DESCENDING): el índice ya está ordenado y evita el SORT. FAST FULL SCAN: el índice leído como tabla.
PROMPT 3. SKIP SCAN: filtrar por la 2.ª columna cuando la 1.ª tiene pocos valores (es un parche, no un diseño).
PROMPT 4. Una expresión sobre la columna (importe * 2, TO_CHAR(fecha)) anula el índice y deja al optimizador con una
PROMPT    conjetura fija (5 %). Reescribe el predicado para que la columna quede limpia.
EXIT
