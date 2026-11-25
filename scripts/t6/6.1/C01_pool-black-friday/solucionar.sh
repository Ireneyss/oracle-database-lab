#!/usr/bin/env bash
# C01 · solucionar · dimensionar el pool a la capacidad: 2 sesiones (= CPU_COUNT) durante 40 s, y registrar la línea base
# Por qué: la ley de Little (concurrencia = throughput × latencia). Si el throughput ya no crece, más concurrencia
#          solo alarga la cola. Un pool del tamaño de la capacidad atiende lo mismo con mucha menos latencia.
# Efectos: filas C01_N2 en T6.APP_LOG y T6.C01_TANDA, y la línea base del panel en T6.LINEA_BASE. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
titulo "Pool dimensionado: 2 sesiones de la aplicación (CPU_COUNT = 2) durante 40 s"
dba <<'SQL' > /dev/null
DELETE FROM t6.app_log WHERE etq = 'C01_N2';
DELETE FROM t6.c01_tanda WHERE etq = 'C01_N2';
INSERT INTO t6.c01_tanda VALUES ('C01_N2', 2, SYSTIMESTAMP, NULL);
COMMIT;
SQL
carga C01_N2 2 40 "t6.app.panel_ventas"
dba <<'SQL' > /dev/null
UPDATE t6.c01_tanda SET fin = SYSTIMESTAMP WHERE etq = 'C01_N2';
COMMIT;
SQL
titulo "Línea base de la sentencia del panel (lo que se anota ANTES de tocar el SQL): t6 base registrar"
sid=$(dba <<'SQL' | tr -d ' '
SELECT sql_id FROM v$sqlstats WHERE sql_text LIKE 'SELECT /*+ t6_panel */%' AND ROWNUM = 1;
SQL
)
echo "   SQL_ID del panel de ventas: $sid"
sesion DBA "/ as sysdba" <<SQL
ALTER SESSION SET CONTAINER = FREEPDB1;
DELETE FROM t6.linea_base WHERE caso = 'C01';
INSERT INTO t6.linea_base (caso, etiqueta, sql_id, plan_hash, ejecuciones, ms_ejec, cpu_ms_ejec, gets_ejec, filas_ejec, nota)
SELECT 'C01', 'panel tras C01', sql_id, plan_hash_value, executions,
       ROUND(elapsed_time / executions / 1000, 2), ROUND(cpu_time / executions / 1000, 2),
       ROUND(buffer_gets / executions), ROUND(rows_processed / executions), 'pool de 2 sesiones'
  FROM v\$sqlstats WHERE sql_id = '$sid';
COMMIT;
SELECT caso, etiqueta, sql_id, plan_hash, ejecuciones, ms_ejec, cpu_ms_ejec, gets_ejec FROM t6.linea_base WHERE caso = 'C01';
SQL
