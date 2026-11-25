-- C02 · solucionar · la misma carga con COMMIT cada 1 000 filas (la unidad de trabajo del negocio es el lote)
-- Por qué: la durabilidad se garantiza en cada COMMIT; confirmar por lote mantiene la garantía y elimina 19 980 esperas.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == Cargando 20 000 ventas con COMMIT cada 1 000 filas ... ==
@@_medir 1000 POR_LOTE
SELECT etq, ms_total, ROUND(20000 / (ms_total / 1000)) AS filas_seg FROM t6.c02_medida ORDER BY ms_total DESC;
EXIT
