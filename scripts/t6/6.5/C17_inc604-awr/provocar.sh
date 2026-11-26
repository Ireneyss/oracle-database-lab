#!/usr/bin/env bash
# C17 · provocar · INC-604 «La pantalla de pedidos por código postal va lenta desde el despliegue del lunes»
# Qué hace : instantánea AWR, 3 sesiones de la web durante 120 s con la versión en producción (V1), instantánea AWR.
#            Cada usuario «piensa» 20 ms entre dos búsquedas (la misma pausa en la V2, para comparar con la misma carga).
#            Los números de las instantáneas quedan en T6.C17_SNAP para las fases siguientes. Unos 2 minutos.
# Efectos  : tabla T6.C17_SNAP, filas C17_V1 en T6.APP_LOG y un intervalo AWR. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
snap() {   # snap ETIQUETA: instantánea AWR de la PDB y la apunta en T6.C17_SNAP
  dba <<SQL | tr -d ' '
SET SERVEROUTPUT ON
DECLARE s NUMBER;
BEGIN
  s := DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
  INSERT INTO t6.c17_snap VALUES ('$1', s, SYSTIMESTAMP);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('$1=' || s);
END;
/
SQL
}
dba <<'SQL' > /dev/null
DELETE FROM t6.app_log WHERE etq LIKE 'C17%';
DELETE FROM t6.linea_base WHERE caso = 'C17';
DECLARE n NUMBER; BEGIN SELECT COUNT(*) INTO n FROM dba_tables WHERE owner = 'T6' AND table_name = 'C17_SNAP';
  IF n = 0 THEN EXECUTE IMMEDIATE 'CREATE TABLE t6.c17_snap (etq VARCHAR2(10), snap_id NUMBER, ts TIMESTAMP) TABLESPACE tbs_t6'; END IF; END;
/
DELETE FROM t6.c17_snap;
COMMIT;
SQL
titulo "Línea base del incidente: instantánea AWR, la web en producción (V1) y otra instantánea"
paso "Instantánea AWR inicial"
snap V1_INI
carga C17_V1 3 120 "t6.app.buscar_cp_v1(30001 + MOD(i * 37, 5000))" 0.005
paso "Instantánea AWR final"
snap V1_FIN
paso "Hecho. Atención al cliente ha abierto el INC-604. Siguiente fase: caso C17 entender"
paso "Línea base ANTES de tocar nada (runbook RB-1): t6 base registrar ANTES SQL_ID C17"
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
SQLID=$(dba <<'SQL' | tr -d '[:space:]'
SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1;
SQL
)
bash "$KIT6/t6.sh" base registrar ANTES "$SQLID" C17 | grep -av '^$' | tail -6
