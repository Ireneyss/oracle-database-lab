#!/usr/bin/env bash
# C07 · provocar · la pantalla «Pedidos por código postal» de la web: 40 búsquedas con la versión en producción (V1)
# V1 recibe el código postal como NUMBER, pero la columna T6.PEDIDO.CODIGO_POSTAL es VARCHAR2(5) y tiene índice.
# Efectos: filas C07_V1 en T6.APP_LOG. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL' > /dev/null
DELETE FROM t6.app_log WHERE etq LIKE 'C07%';
COMMIT;
SQL
sesion APP "$APP" <<'SQL'
SET ECHO OFF
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('tienda_web', 'C07_V1');
  t6.app.etiqueta('C07_V1');
  FOR i IN 1 .. 40 LOOP t6.app.buscar_cp_v1(30001 + MOD(i * 37, 500)); END LOOP;
  COMMIT;
END;
/
SELECT 'Búsquedas hechas: ' || COUNT(*) AS resultado FROM user_tab_privs WHERE ROWNUM = 1;
SQL
dba <<'SQL'
SELECT 'Búsquedas registradas por la web (C07_V1): ' || COUNT(*) FROM t6.app_log WHERE etq = 'C07_V1';
SQL
