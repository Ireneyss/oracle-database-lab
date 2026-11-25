#!/usr/bin/env bash
# C17 · validar · la misma carga (3 sesiones, 120 s) con la V2, entre dos instantáneas nuevas, y las comprobaciones
# Efectos: filas C17_V2 en T6.APP_LOG y un segundo intervalo AWR. Unos 2 minutos. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
snap() {
  dba <<SQL > /dev/null
DECLARE s NUMBER;
BEGIN
  s := DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT;
  DELETE FROM t6.c17_snap WHERE etq = '$1';
  INSERT INTO t6.c17_snap VALUES ('$1', s, SYSTIMESTAMP);
  COMMIT;
END;
/
SQL
}
dba <<'SQL' > /dev/null
DELETE FROM t6.app_log WHERE etq = 'C17_V2';
COMMIT;
SQL
snap V2_INI
carga C17_V2 3 120 "t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 5000)))" 0.005
snap V2_FIN
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
SQLID=$(dba <<'SQL' | tr -d '[:space:]'
SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%' AND ROWNUM = 1;
SQL
)
bash "$KIT6/t6.sh" base registrar DESPUES "$SQLID" C17 > /dev/null 2>&1
dba <<'SQL'
WITH t AS (SELECT etq, PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ms) p95, COUNT(*) n FROM t6.app_log
            WHERE etq IN ('C17_V1', 'C17_V2') GROUP BY etq),
     s AS (SELECT MAX(DECODE(etq, 'V1_INI', snap_id)) a1, MAX(DECODE(etq, 'V1_FIN', snap_id)) a2,
                  MAX(DECODE(etq, 'V2_INI', snap_id)) b1, MAX(DECODE(etq, 'V2_FIN', snap_id)) b2 FROM t6.c17_snap),
     w AS (SELECT CASE WHEN q.snap_id <= s.a2 THEN 'V1' ELSE 'V2' END AS v,
                  SUM(q.buffer_gets_delta) / NULLIF(SUM(q.executions_delta), 0) AS gets
             FROM awr_pdb_sqlstat q, s
            WHERE ((q.snap_id > s.a1 AND q.snap_id <= s.a2) OR (q.snap_id > s.b1 AND q.snap_id <= s.b2))
              AND q.sql_id IN (SELECT sql_id FROM awr_pdb_sqltext WHERE DBMS_LOB.SUBSTR(sql_text, 30, 1) LIKE 'SELECT /*+ t6_cp_v%')
            GROUP BY CASE WHEN q.snap_id <= s.a2 THEN 'V1' ELSE 'V2' END)
SELECT CASE WHEN v2.p95 < 20 THEN 'OK    ' ELSE 'FALLO ' END || 'SLO de la búsqueda: p95 V2 = ' || ROUND(v2.p95, 2)
       || ' ms (< 20) · antes ' || ROUND(v1.p95, 1) || ' ms' AS resultado
  FROM t v1, t v2 WHERE v1.etq = 'C17_V1' AND v2.etq = 'C17_V2'
UNION ALL
SELECT CASE WHEN v2.n > 3 * v1.n THEN 'OK    ' ELSE 'FALLO ' END || 'Capacidad con la misma carga: ' || v2.n || ' búsquedas frente a ' || v1.n
  FROM t v1, t v2 WHERE v1.etq = 'C17_V1' AND v2.etq = 'C17_V2'
UNION ALL
SELECT CASE WHEN b.gets * 10 < a.gets THEN 'OK    ' ELSE 'FALLO ' END || 'AWR (deltas del intervalo): lecturas por ejecución '
       || ROUND(b.gets) || ' en V2 frente a ' || ROUND(a.gets) || ' en V1'
  FROM w a, w b WHERE a.v = 'V1' AND b.v = 'V2'
UNION ALL
SELECT CASE WHEN COUNT(DISTINCT etiqueta) = 2 THEN 'OK    ' ELSE 'FALLO ' END || 'Línea base ANTES y DESPUES registradas (t6 base ver C17)'
  FROM t6.linea_base WHERE caso = 'C17'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'La V2 usa el índice IX_T6_PED_CP'
  FROM v$sql_plan WHERE object_name = 'IX_T6_PED_CP'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%');
SQL
