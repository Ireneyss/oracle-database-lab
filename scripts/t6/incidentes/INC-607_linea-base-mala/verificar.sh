#!/usr/bin/env bash
# INC-607 · verificar · el historial se ejecuta como la aplicación (T6_APP) con el cliente de tu semilla
source "$(dirname "$0")/../../_comun.sh"
cli=$((1000 + SEMILLA * 97))
sesion APP "$APP" <<SQL > /dev/null
SET TERMOUT OFF
VARIABLE c NUMBER
EXEC :c := $cli
SELECT /* t6_inc607_historial */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c;
SELECT /* t6_inc607_historial */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c;
SELECT /* t6_inc607_historial */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c;
SQL
dba <<SQL
@/tmp/t6/incidentes/_cabecera_verificar INC-607 $SEMILLA $ESTUDIANTE
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'No queda ninguna línea base FIXED activa para el historial'
  FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_inc607_historial */%' AND fixed = 'YES' AND enabled = 'YES';
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El historial del cliente $cli usa un índice por ID_CLIENTE'
  FROM v\$sql_plan WHERE operation = 'INDEX' AND object_name IN (SELECT index_name FROM dba_ind_columns WHERE index_owner = 'T6'
       AND table_name = 'PEDIDO' AND column_name = 'ID_CLIENTE' AND column_position = 1)
   AND sql_id IN (SELECT sql_id FROM v\$sql WHERE sql_text LIKE 'SELECT /* t6_inc607_historial */%' AND parsing_schema_name = 'T6_APP');
SELECT CASE WHEN MIN(buffer_gets / executions) < 1000 THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas por historial (media de 3, incluye el primer análisis; el recorrido completo pasa de 5 000): '
       || ROUND(MIN(buffer_gets / executions)) FROM v\$sql WHERE sql_text LIKE 'SELECT /* t6_inc607_historial */%' AND parsing_schema_name = 'T6_APP';
SQL
