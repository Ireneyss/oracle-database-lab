#!/usr/bin/env bash
# INC-610 · verificar · parámetro de la PDB y plan de la V2 en una sesión NUEVA de la aplicación
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL' > /dev/null
ALTER SYSTEM FLUSH SHARED_POOL;
SQL
sesion APP "$APP" <<'SQL' > /dev/null
BEGIN FOR i IN 1 .. 20 LOOP t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 5000))); END LOOP; ROLLBACK; END;
/
SQL
dba <<SQL
@/tmp/t6/incidentes/_cabecera_verificar INC-610 $SEMILLA $ESTUDIANTE
SELECT CASE WHEN value = '100' THEN 'OK    ' ELSE 'FALLO ' END || 'optimizer_index_cost_adj de FREEPDB1 = ' || value || ' (por defecto, 100)'
  FROM v\$system_parameter WHERE name = 'optimizer_index_cost_adj';
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'No queda el valor guardado en el SPFILE de la PDB (se quitó con RESET)'
  FROM v\$spparameter WHERE name = 'optimizer_index_cost_adj' AND isspecified = 'TRUE'
   AND con_id = (SELECT con_id FROM v\$pdbs WHERE name = 'FREEPDB1');
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'La V2 de la búsqueda vuelve a usar IX_T6_PED_CP'
  FROM v\$sql_plan WHERE object_name = 'IX_T6_PED_CP'
   AND sql_id IN (SELECT sql_id FROM v\$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%');
SQL
