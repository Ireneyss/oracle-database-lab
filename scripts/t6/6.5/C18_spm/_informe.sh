# C18 · _informe.sh · la aplicación (T6_APP) ejecuta N veces el informe de pedidos pendientes, con la etiqueta ETQ
# Uso (desde los pasos del caso): informe ETQ N
Q18="SELECT /* t6_c18_pendientes */ COUNT(*), SUM(importe), MAX(fecha_pedido) FROM t6.pedido WHERE estado = 'P'"
informe() {
  local etq="$1" n="$2" k
  { echo "SET TERMOUT OFF"; echo "EXEC DBMS_APPLICATION_INFO.SET_MODULE('informes', '$etq')"
    for ((k = 1; k <= n; k++)); do echo "$Q18;"; done
    echo "SET TERMOUT ON"; } | sesion APP "$APP" > /dev/null
  dba <<SQL
DELETE FROM t6.c18_medida WHERE etq = '$etq';
INSERT INTO t6.c18_medida
SELECT '$etq', plan_hash_value, ROUND(buffer_gets / executions), ROUND(elapsed_time / executions / 1000, 1), sql_plan_baseline
  FROM v\$sql WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND parsing_schema_name = 'T6_APP'
   AND is_shareable = 'Y' ORDER BY last_active_time DESC FETCH FIRST 1 ROW ONLY;
COMMIT;
SELECT RPAD(etq, 12) || ' plan ' || plan_hash || '  ' || gets || ' lecturas/ejecución  ' || ms || ' ms  línea base: '
       || NVL(linea_base, '(ninguna)') FROM t6.c18_medida WHERE etq = '$etq';
SQL
}
