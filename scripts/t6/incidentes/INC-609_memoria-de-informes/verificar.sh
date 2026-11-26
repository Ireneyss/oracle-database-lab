#!/usr/bin/env bash
# INC-609 · verificar · una sesión NUEVA de la aplicación ejecuta el informe y se miran su política y sus áreas de trabajo
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL' > /dev/null
ALTER SYSTEM FLUSH SHARED_POOL;
SQL
pol=$(sesion APP "$APP" <<'SQL' | grep -ao 'POLITICA=[A-Z]\+' | head -1
SET TERMOUT OFF
SELECT /* t6_inc609_informe */ id_cliente, COUNT(*), SUM(importe) FROM t6.pedido GROUP BY id_cliente ORDER BY 3 DESC;
SET TERMOUT ON
SELECT 'POLITICA=' || value FROM v$parameter WHERE name = 'workarea_size_policy';
SQL
)
dba <<SQL
@/tmp/t6/incidentes/_cabecera_verificar INC-609 $SEMILLA $ESTUDIANTE
SELECT CASE WHEN '${pol#POLITICA=}' = 'AUTO' THEN 'OK    ' ELSE 'FALLO ' END || 'Una sesión nueva de T6_APP trabaja con workarea_size_policy = ${pol#POLITICA=}' FROM dual;
SELECT CASE WHEN NVL(SUM(onepass_executions + multipasses_executions), 1) = 0 THEN 'OK    ' ELSE 'FALLO ' END
       || 'El informe no se desborda a TEMP (una pasada: ' || NVL(SUM(onepass_executions), 0) || ', varias: ' || NVL(SUM(multipasses_executions), 0) || ')'
  FROM v\$sql_workarea w JOIN v\$sql s ON s.sql_id = w.sql_id AND s.child_number = w.child_number
 WHERE s.sql_text LIKE 'SELECT /* t6_inc609_informe */%';
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Ningún disparador de logon activo cambia la memoria de T6_APP'
  FROM dba_triggers WHERE owner = 'T6' AND triggering_event LIKE 'LOGON%' AND status = 'ENABLED';
SQL
