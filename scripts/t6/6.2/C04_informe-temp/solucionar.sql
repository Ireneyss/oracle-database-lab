-- C04 · solucionar · dos cambios, cada uno medido: (1) retirar la configuración heredada (vuelve la PGA automática);
-- (2) reducir ANTES de ordenar: la pantalla solo necesita las 100 primeras filas (FETCH FIRST 100 ROWS ONLY).
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO ON
DROP TRIGGER t6.c04_legado;
SET ECHO OFF
PROMPT == 1 · El mismo informe completo, ahora con la PGA automática ==
@@_informe AUTO_COMPLETO COMPLETO
PROMPT == 2 · El informe que de verdad necesita la pantalla: las 100 primeras filas ==
@@_informe AUTO_TOP100 TOP100
SELECT modo, filas, ms, temp_escritos, temp_leidos, politica FROM t6.c04_medida ORDER BY ms DESC;
EXIT
