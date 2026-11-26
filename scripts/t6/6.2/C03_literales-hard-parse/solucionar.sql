-- C03 · solucionar · la versión corregida de la aplicación: variable de enlace (:id). Un solo cursor compartido.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
ALTER SYSTEM FLUSH SHARED_POOL;
PROMPT == 5 000 fichas con la versión corregida (variable de enlace) ... ==
@@_medir BIND
SELECT modo, llamadas, ms_total, hard_parses, ROUND(ms_total / llamadas, 3) AS ms_por_ficha FROM t6.c03_medida ORDER BY ms_total DESC;
EXIT
