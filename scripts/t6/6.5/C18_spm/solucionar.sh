#!/usr/bin/env bash
# C18 · solucionar · recuperar el plan del lunes DESDE AWR como línea base aceptada (SPM) y repetir el informe
# Equivale a:  t6 spm lista c18   (y para cargar desde la caché de cursores: t6 spm cargar SQL_ID)
source "$(dirname "$0")/../../_comun.sh"
source "$(dirname "$0")/_informe.sh"
titulo "1 · Cargar el plan del lunes desde el AWR de la PDB como línea base (SQL plan baseline)"
sesion DBA "/ as sysdba" <<'SQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON
COLUMN origin FORMAT A26
COLUMN plan_name FORMAT A32
DECLARE n PLS_INTEGER; i NUMBER; f NUMBER; bueno NUMBER;
BEGIN
  SELECT MAX(DECODE(etq, 'LUNES_INI', snap_id)), MAX(DECODE(etq, 'LUNES_FIN', snap_id)) INTO i, f FROM t6.c18_snap;
  -- el plan del lunes se elige por sus NÚMEROS en AWR: el de menos lecturas por ejecución en ese intervalo
  SELECT plan_hash_value INTO bueno FROM (
    SELECT q.plan_hash_value, SUM(q.buffer_gets_delta) / NULLIF(SUM(q.executions_delta), 0) g
      FROM awr_pdb_sqlstat q JOIN awr_pdb_sqltext t ON t.sql_id = q.sql_id
     WHERE q.snap_id > i AND q.snap_id <= f AND DBMS_LOB.SUBSTR(t.sql_text, 40, 1) LIKE 'SELECT /* t6_c18_pendientes */%'
     GROUP BY q.plan_hash_value HAVING SUM(q.executions_delta) > 0 ORDER BY g FETCH FIRST 1 ROW ONLY);
  DBMS_OUTPUT.PUT_LINE('Plan del lunes en AWR (snapshots ' || i || ' a ' || f || '): ' || bueno);
  n := DBMS_SPM.LOAD_PLANS_FROM_AWR(begin_snap => i, end_snap => f,
         basic_filter => q'[sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND plan_hash_value = ]' || bueno);
  DBMS_OUTPUT.PUT_LINE('Planes cargados desde AWR como línea base aceptada: ' || n);
END;
/
SELECT plan_name, enabled, accepted, fixed, origin FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%';
SQL
titulo "2 · El mismo informe, con las estadísticas del martes (sin histograma)"
informe CON_SPM 20
sesion DBA "/ as sysdba" <<'SQL'
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 160
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND sql_plan_baseline IS NOT NULL AND ROWNUM = 1),
  (SELECT MAX(child_number) FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND sql_plan_baseline IS NOT NULL),
  'BASIC +ROWS +NOTE'));
SQL
