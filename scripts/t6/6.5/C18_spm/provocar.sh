#!/usr/bin/env bash
# C18 · provocar · el lunes el informe de pendientes va bien; el martes, tras la recogida nocturna, va lento
# Qué hace : (1) estadísticas con histograma en ESTADO y el informe de la aplicación (plan bueno, entre dos
#            instantáneas AWR: el plan queda guardado en el repositorio); (2) la recogida «nocturna» con las
#            preferencias de la tabla (METHOD_OPT ... SIZE 1) borra el histograma; (3) el mismo informe, otro plan.
# Efectos  : estadísticas de T6.PEDIDO, un intervalo AWR y las tablas T6.C18_SNAP y T6.C18_MEDIDA. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
source "$(dirname "$0")/_informe.sh"
dba <<'SQL' > /dev/null
DECLARE n NUMBER; BEGIN SELECT COUNT(*) INTO n FROM dba_tables WHERE owner = 'T6' AND table_name = 'C18_SNAP';
  IF n = 0 THEN EXECUTE IMMEDIATE 'CREATE TABLE t6.c18_snap (etq VARCHAR2(10), snap_id NUMBER) TABLESPACE tbs_t6';
    EXECUTE IMMEDIATE 'CREATE TABLE t6.c18_medida (etq VARCHAR2(10), plan_hash NUMBER, gets NUMBER, ms NUMBER, linea_base VARCHAR2(128)) TABLESPACE tbs_t6';
  END IF; END;
/
DELETE FROM t6.c18_snap;
DELETE FROM t6.c18_medida;
DECLARE n PLS_INTEGER;
BEGIN
  FOR b IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE sql_text LIKE '%t6_c18_pendientes%') LOOP
    n := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => b.sql_handle); END LOOP;
END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR ALL COLUMNS SIZE 1 FOR COLUMNS estado SIZE 254', no_invalidate => FALSE)
COMMIT;
SQL
titulo "Lunes: el informe de pendientes con el histograma de ESTADO (y AWR guardando lo que pasa)"
dba <<'SQL' > /dev/null
INSERT INTO t6.c18_snap VALUES ('LUNES_INI', DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT);
COMMIT;
SQL
informe LUNES 20
dba <<'SQL' > /dev/null
INSERT INTO t6.c18_snap VALUES ('LUNES_FIN', DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT);
COMMIT;
SQL
titulo "Noche: la tarea de estadísticas recoge PEDIDO con las preferencias de la tabla (SIZE 1: sin histograma)"
dba <<'SQL'
-- la preferencia de la tabla que dejó «alguien» (la misma que en INC-608): SIZE 1, sin histogramas
EXEC DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO', 'METHOD_OPT', 'FOR ALL COLUMNS SIZE 1')
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', no_invalidate => FALSE)
SELECT 'Preferencia METHOD_OPT de PEDIDO: ' || DBMS_STATS.GET_PREFS('METHOD_OPT', 'T6', 'PEDIDO') FROM dual;
SQL
titulo "Martes: el mismo informe"
informe MARTES 20
paso "Hecho. Los de finanzas dicen que «el informe de pendientes tarda más desde hoy». Siguiente fase: caso C18 entender"
