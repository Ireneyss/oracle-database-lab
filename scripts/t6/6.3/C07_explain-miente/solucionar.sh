#!/usr/bin/env bash
# C07 · solucionar · desplegar la versión V2: el parámetro tiene el MISMO tipo que la columna (VARCHAR2)
# Un solo cambio, y en la aplicación: no se crea ningún índice ni se toca ningún parámetro.
source "$(dirname "$0")/../../_comun.sh"
sesion APP "$APP" <<'SQL'
SET ECHO OFF
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('tienda_web', 'C07_V2');
  t6.app.etiqueta('C07_V2');
  FOR i IN 1 .. 40 LOOP t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 500))); END LOOP;
  COMMIT;
END;
/
SQL
sesion DBA "/ as sysdba" <<'SQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%' AND ROWNUM = 1), NULL, 'TYPICAL -BYTES'));
SQL
