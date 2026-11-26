#!/usr/bin/env bash
# C20 · validar · cada línea dice OK o FALLO
source "$(dirname "$0")/../../_comun.sh"
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
f="$KIT6/salidas/tkprof_C20.prf"
[ -s "$f" ] && echo "OK    Hay informe tkprof del módulo: salidas/tkprof_C20.prf" || echo "FALLO No hay informe tkprof (repite: caso C20 diagnosticar)"
grep -aq 't6_panel' "$f" 2>/dev/null && echo "OK    El informe contiene el panel de ventas (la sentencia de los tirones)" || echo "FALLO El informe no contiene el panel de ventas"
n=$(dba <<'SQL' | tr -d '[:space:]'
SELECT COUNT(*) FROM dba_enabled_traces;
SQL
)
[ "${n:-1}" = 0 ] && echo "OK    No queda ninguna traza activa (DBA_ENABLED_TRACES vacía)" || echo "FALLO Quedan $n trazas activas: t6 traza off tienda_web C20_ALTA"
