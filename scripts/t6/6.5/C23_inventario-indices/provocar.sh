#!/usr/bin/env bash
# C23 · provocar · desarrollo pide «un índice por (id_cliente, fecha_pedido) para el historial del cliente». Antes de
#          crearlo, el DBA hace inventario. Para que haya algo que encontrar, alguien dejó dos índices de más hace tiempo.
# Efectos: índices IX_C23_CLI_FECHA e IX_C23_CLI_DUP en T6.PEDIDO; 30 s de la aplicación. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
dba <<'SQL'
BEGIN FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'T6' AND index_name LIKE 'IX_C23%') LOOP
  EXECUTE IMMEDIATE 'DROP INDEX t6.' || i.index_name; END LOOP; END;
/
CREATE INDEX t6.ix_c23_cli_fecha ON t6.pedido (id_cliente, fecha_pedido) TABLESPACE tbs_t6;
SELECT 'Índices de PEDIDO ahora: ' || COUNT(*) FROM dba_indexes WHERE owner = 'T6' AND table_name = 'PEDIDO';
SQL
titulo "La web trabaja 30 s (fichas y búsquedas por código postal) para que haya uso que registrar"
carga C23_WEB 2 30 "t6.app.ficha_bind(MOD(i * 7919, 100000) + 1); t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 5000)))"
