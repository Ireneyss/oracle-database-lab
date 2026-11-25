#!/usr/bin/env bash
# C21 · provocar · ADDM dijo «Run SQL Tuning Advisor on the SELECT statement»: la búsqueda V1 del INC-604 vuelve a la caché
# Efectos: filas C21_V1 en T6.APP_LOG. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL' > /dev/null
BEGIN FOR t IN (SELECT task_name FROM dba_advisor_tasks WHERE task_name IN ('T6_C21_STA', 'T6_C21_SAA')) LOOP
  DBMS_ADVISOR.DELETE_TASK(t.task_name); END LOOP; END;
/
BEGIN FOR p IN (SELECT name FROM dba_sql_profiles WHERE name LIKE 'T6_C21%' OR (category = 'DEFAULT' AND sql_text LIKE '%t6_cp_v1%')) LOOP
  DBMS_SQLTUNE.DROP_SQL_PROFILE(p.name); END LOOP; END;
/
SQL
carga C21_V1 1 10 "t6.app.buscar_cp_v1(30001 + MOD(i * 37, 5000))"
dba <<'SQL'
SELECT 'La búsqueda V1 está en la caché: SQL_ID ' || sql_id || ', ' || executions || ' ejecuciones, '
       || ROUND(buffer_gets / executions) || ' lecturas cada una' FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1;
SQL
