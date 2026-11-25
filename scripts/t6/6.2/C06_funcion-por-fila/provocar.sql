-- C06 · provocar · el total con IVA del panel: la regla de negocio vive en una función PL/SQL que se llama en cada fila
-- Efectos: crea T6.CON_IVA y T6.CONTADOR (cuenta las llamadas reales). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT ON
CREATE OR REPLACE PACKAGE t6.contador AS n NUMBER := 0; END;
/
CREATE OR REPLACE FUNCTION t6.con_iva(p NUMBER) RETURN NUMBER IS
BEGIN
  t6.contador.n := t6.contador.n + 1;     -- solo para contar las llamadas reales
  RETURN ROUND(p * 1.21, 2);
END;
/
EXEC t6.contador.n := 0
SET TIMING ON
SELECT /* t6_c06 plsql */ SUM(t6.con_iva(importe)) AS total FROM t6.pedido;
SET TIMING OFF
EXEC DBMS_OUTPUT.PUT_LINE('llamadas reales a la función: ' || t6.contador.n)
EXIT
