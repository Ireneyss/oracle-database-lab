#!/usr/bin/env bash
# C17 · diagnosticar · de lo general a lo concreto: ASH (¿quién y en qué?), AWR (¿qué SQL del intervalo?),
#                      ADDM (¿qué dice el diagnóstico automático?) y, al final, el plan real del cursor.
# Equivale a:  t6 ash 10 tienda_web  ·  t6 awr top INI FIN  ·  t6 awr addm INI FIN  ·  t6 plan SQL_ID
source "$(dirname "$0")/../../_comun.sh"
read -r S1 S2 < <(dba <<'SQL' | tr '\n' ' '
SELECT MAX(DECODE(etq, 'V1_INI', snap_id)) || ' ' || MAX(DECODE(etq, 'V1_FIN', snap_id)) FROM t6.c17_snap;
SQL
)
[ -n "${S2:-}" ] || { echo "Falta el intervalo AWR: ejecuta antes  caso C17 provocar"; exit 2; }
titulo "1 · ASH: muestras de la web en los últimos 10 minutos, por acción, SQL y evento"
sesion DBA "/ as sysdba" <<'SQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN action FORMAT A10
COLUMN evento FORMAT A24
SELECT action, sql_id, NVL(event, 'ON CPU') AS evento, COUNT(*) AS muestras
  FROM v$active_session_history
 WHERE module = 'tienda_web' AND action = 'C17_V1' AND sample_time > SYSDATE - 10 / 1440
 GROUP BY action, sql_id, NVL(event, 'ON CPU') ORDER BY muestras DESC FETCH FIRST 5 ROWS ONLY;
SQL
titulo "2 · AWR: las sentencias con más tiempo en el intervalo $S1 → $S2 (deltas)"
sesion DBA "/ as sysdba" <<SQL
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN texto FORMAT A42
SELECT s.sql_id, s.plan_hash_value AS plan_hash, SUM(s.executions_delta) AS ejec, ROUND(SUM(s.elapsed_time_delta) / 1e6, 1) AS seg,
       ROUND(SUM(s.buffer_gets_delta) / NULLIF(SUM(s.executions_delta), 0)) AS gets_ejec,
       (SELECT SUBSTR(REGEXP_REPLACE(DBMS_LOB.SUBSTR(t.sql_text, 200, 1), '\s+', ' '), 1, 42) FROM awr_pdb_sqltext t
         WHERE t.sql_id = s.sql_id AND ROWNUM = 1) AS texto
  FROM awr_pdb_sqlstat s WHERE s.snap_id > $S1 AND s.snap_id <= $S2
 GROUP BY s.sql_id, s.plan_hash_value ORDER BY seg DESC FETCH FIRST 4 ROWS ONLY;
SQL
titulo "3 · ADDM del intervalo $S1 → $S2 (solo los hallazgos y las recomendaciones)"
sesion DBA "/ as sysdba" <<SQL | grep -aE 'Total database time|average number of active|There are no findings|Summary of Findings|Finding [0-9]|Impact is|Recommendation [0-9]|Run SQL Tuning|was executed [0-9]+ times|^\[DBA\] +[0-9] +[A-Z]' | head -24
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SET LONG 1000000 LONGCHUNKSIZE 1000000 PAGESIZE 0 LINESIZE 130
VARIABLE tarea VARCHAR2(60)
EXEC :tarea := 'T6_C17_ADDM'
BEGIN DBMS_ADDM.DELETE(:tarea); EXCEPTION WHEN OTHERS THEN NULL; END;
/
EXEC DBMS_ADDM.ANALYZE_DB(:tarea, $S1, $S2)
SELECT DBMS_ADDM.GET_REPORT(:tarea) FROM dual;
SQL
titulo "4 · El plan REAL del SQL que señalan ASH, AWR y ADDM: mira los predicados"
sesion DBA "/ as sysdba" <<'SQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1), NULL, 'TYPICAL -BYTES -NOTE -HINT_REPORT'));
SQL
paso "Lectura: TABLE ACCESS FULL con filter(TO_NUMBER(\"CODIGO_POSTAL\")=:B1). La V1 pasa un NUMBER contra una columna"
paso "VARCHAR2: Oracle convierte la COLUMNA en cada fila y el índice IX_T6_PED_CP no se puede usar (como en C07)."
