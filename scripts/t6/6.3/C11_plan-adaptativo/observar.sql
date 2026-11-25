-- C11 · observar · los parámetros que gobiernan la adaptación y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN name FORMAT A36
COLUMN value FORMAT A10
SELECT name, value FROM v$parameter WHERE name LIKE 'optimizer_adaptive%';
PROMPT == Lo que debes retener ==
PROMPT 1. Plan adaptativo: el optimizador deja preparados NESTED LOOPS y HASH JOIN y decide con las filas reales.
PROMPT 2. Se lee con DISPLAY_CURSOR(format => '+ADAPTIVE'): «-» = línea inactiva. IS_RESOLVED_ADAPTIVE_PLAN = Y.
PROMPT 3. Solo decide la primera ejecución: las siguientes reutilizan el plan final (no es un plan que cambie siempre).
EXIT
