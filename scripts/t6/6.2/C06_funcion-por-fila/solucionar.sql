-- C06 · solucionar · la regla escrita en SQL: ningún cambio de contexto (y la misma cifra)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
SET TIMING ON
SELECT /* t6_c06 sql */ SUM(ROUND(importe * 1.21, 2)) AS total FROM t6.pedido;
SET TIMING OFF
EXIT
