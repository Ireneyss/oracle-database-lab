#!/usr/bin/env bash
# INC-606 · verificar · la V2 se ejecuta como la aplicación (T6_APP) y se mira su plan
source "$(dirname "$0")/../../_comun.sh"
sesion APP "$APP" <<'SQL' > /dev/null
BEGIN FOR i IN 1 .. 20 LOOP t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 5000))); END LOOP; ROLLBACK; END;
/
SQL
dba <<SQL
@/tmp/t6/incidentes/_cabecera_verificar INC-606 $SEMILLA $ESTUDIANTE
SELECT CASE WHEN status = 'VALID' AND visibility = 'VISIBLE' THEN 'OK    ' ELSE 'FALLO ' END
       || 'IX_T6_PED_CP: ' || status || ' y ' || visibility FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_PED_CP';
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'La V2 de la aplicación vuelve a usar IX_T6_PED_CP'
  FROM v\$sql_plan WHERE object_name = 'IX_T6_PED_CP'
   AND sql_id IN (SELECT sql_id FROM v\$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%');
SELECT CASE WHEN MAX(buffer_gets / executions) < 500 THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas por búsqueda: '
       || ROUND(MAX(buffer_gets / executions)) FROM v\$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%'
   AND last_active_time > SYSDATE - 2 / 1440;
SQL
