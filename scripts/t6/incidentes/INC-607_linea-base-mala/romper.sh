#!/usr/bin/env bash
# INC-607 · romper · alguien «fijó» con SPM un plan de recorrido completo para el historial del cliente (FIXED = YES)
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL' > /dev/null
DECLARE n PLS_INTEGER;
BEGIN
  FOR b IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE sql_text LIKE '%t6_inc607%') LOOP
    n := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => b.sql_handle); END LOOP;
END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
SQL
sesion APP "$APP" <<'SQL' > /dev/null
SET TERMOUT OFF
VARIABLE c NUMBER
EXEC :c := 4242
SELECT /* t6_inc607_historial */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c;
SELECT /*+ FULL(p) */ /* t6_inc607_aux */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c;
SQL
dba <<SQL > /dev/null
DECLARE n PLS_INTEGER; s_aux VARCHAR2(13); ph NUMBER; txt CLOB;
BEGIN
  SELECT sql_fulltext INTO txt FROM v\$sql WHERE sql_text LIKE 'SELECT /* t6_inc607_historial */%' AND ROWNUM = 1;
  SELECT sql_id, plan_hash_value INTO s_aux, ph FROM v\$sql WHERE sql_text LIKE 'SELECT /*+ FULL(p) */ /* t6_inc607_aux */%' AND ROWNUM = 1;
  n := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(sql_id => s_aux, plan_hash_value => ph, sql_text => txt, fixed => 'YES');
END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
@/tmp/t6/incidentes/_registro INC-607 $SEMILLA $ESTUDIANTE "línea base FIXED de recorrido completo; cliente de prueba $((1000 + SEMILLA * 97))"
SQL
echo "Roto: el historial de pedidos del cliente (módulo atencion_cliente) ya no va como ayer."
