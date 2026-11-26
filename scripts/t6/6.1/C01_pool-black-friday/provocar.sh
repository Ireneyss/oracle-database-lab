#!/usr/bin/env bash
# C01 · provocar · «Black Friday»: el panel de ventas en directo con 1 sesión y, después, con 8 a la vez
# Qué hace : mide primero la referencia (1 sesión de la aplicación, 20 s) y luego la hora punta (8 sesiones, 40 s),
#            como si el pool de conexiones de la web hubiera crecido «para aguantar más». Cada llamada a
#            T6.APP.PANEL_VENTAS anota su latencia en T6.APP_LOG (la telemetría de la web). Unos 70 s.
# Efectos  : filas en T6.APP_LOG (etiquetas C01_N1 y C01_N8) y en T6.C01_TANDA. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL'
DELETE FROM t6.app_log WHERE etq LIKE 'C01%';
DECLARE n NUMBER; BEGIN SELECT COUNT(*) INTO n FROM dba_tables WHERE owner='T6' AND table_name='C01_TANDA';
  IF n = 0 THEN EXECUTE IMMEDIATE 'CREATE TABLE t6.c01_tanda (etq VARCHAR2(20), sesiones NUMBER, ini TIMESTAMP, fin TIMESTAMP)'; END IF; END;
/
DELETE FROM t6.c01_tanda;
COMMIT;
SQL
tanda() {   # tanda ETQ N SEG
  dba <<SQL > /dev/null
INSERT INTO t6.c01_tanda VALUES ('$1', $2, SYSTIMESTAMP, NULL);
COMMIT;
SQL
  carga "$1" "$2" "$3" "t6.app.panel_ventas"
  dba <<SQL > /dev/null
UPDATE t6.c01_tanda SET fin = SYSTIMESTAMP WHERE etq = '$1';
COMMIT;
SQL
}
titulo "Referencia: 1 sesión de la aplicación (lo normal de un martes)"
tanda C01_N1 1 20
titulo "Hora punta: el pool de la web abre 8 sesiones a la vez («para aguantar más»)"
tanda C01_N8 8 40
paso "Hecho. La web dice que «va lenta». Siguiente fase: caso C01 entender"
