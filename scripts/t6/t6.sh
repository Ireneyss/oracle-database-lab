#!/usr/bin/env bash
# t6.sh · la caja de herramientas de rendimiento del Tema 6 (las que usan los playbooks, los runbooks y los incidentes)
#
#   t6 salud [min]                        ¿más trabajo que CPU? ¿CPU o esperas? ¿quién? (PB-1)            solo lectura
#   t6 top [n] [elapsed|cpu|gets|ejec] [filtro]   sentencias que más pesan (V$SQLSTATS)                   solo lectura
#   t6 plan SQL_ID [hijo]                 plan REAL con E-Rows/A-Rows, predicados y binds (PB-2)          solo lectura
#   t6 ash [min] [sql_id|módulo]          ASH minuto a minuto, por SQL, evento y bloqueos                 solo lectura
#   t6 sesiones [módulo]                  sesiones de usuario activas ahora en FREEPDB1                   solo lectura
#   t6 base registrar ETIQUETA SQL_ID [caso] | t6 base ver [caso]      línea base antes/después (RB-1)
#   t6 estad TABLA [esquema]              estadísticas, obsolescencia, histogramas, pendientes, historial (RB-2)
#   t6 indices TABLA [esquema]            inventario, redundancia, factor de agrupamiento y uso (RB-3)
#   t6 spm lista [filtro] | cargar SQL_ID | evolucionar HANDLE | quitar HANDLE          SQL Plan Management (RB-4)
#   t6 awr snap | lista | top INI FIN | addm INI FIN | informe INI FIN                AWR y ADDM de la PDB (RB-1)
#   t6 traza on MÓDULO [ACCIÓN] | off MÓDULO [ACCIÓN] | tkprof [identificador]       traza y tkprof (RB-5)
#   t6 memoria                            asesores de SGA y PGA, áreas de trabajo                         solo lectura
#   t6 fra [--liberar]                    ocupación de la FRA; --liberar borra archivelogs de más de 1 hora (aula)
#
# «t6» es el alias que crea instalar.sh; sin alias: bash scripts/t6/t6.sh ...  Todas trabajan en FREEPDB1 como SYSDBA.
set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
cd "$KIT"
CONT="${CONT_NAME:-oralab-26ai}"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
mkdir -p salidas
REPO="$(cd "$KIT/../.." && pwd)"

copiar() {
  docker exec -u 0 "$CONT" rm -rf /tmp/t6 && docker cp "$KIT/." "$CONT":/tmp/t6 >/dev/null \
    && docker exec -u 0 "$CONT" bash -c 'chown -R oracle /tmp/t6 2>/dev/null || chmod -R a+rwX /tmp/t6' \
    || { echo "No puedo copiar el kit al contenedor $CONT (¿está en marcha? docker ps)"; exit 2; }
}
filtro() { grep -avE '^(SQL\*Plus: Release|Version [0-9]|Copyright \(c\)|Connected to:|Oracle AI Database|Disconnected from)' | cat -s; }
herr() {   # herr <archivo.sql> args...  (siempre se pasan todos los argumentos: SQL*Plus no debe preguntar nada)
  local f="$1"; shift
  docker exec -e NLS_LANG -w /tmp/t6/herramientas "$CONT" sqlplus -L -s / as sysdba @"$f" "$@" 2>&1 | filtro
}
evidencia() {   # deja copia en docs/bitacora/lab7/evidencia/herramientas si el kit está en el repositorio
  [ -f "$REPO/config/.env" ] && [ -d "$REPO/docs" ] || return 0
  local est; est=$( set -a; . "$REPO/config/.env" > /dev/null 2>&1; printf '%s' "${ESTUDIANTE:-}" )
  [[ "$est" =~ ^E[0-9]{3}$ ]] || return 0
  local d="$REPO/docs/bitacora/lab7/evidencia/herramientas"; mkdir -p "$d"
  local bd
  bd=$(printf '%s\n' "SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 300" \
    "SELECT 'hora=' || TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') || ' contenedor=' || i.host_name || ' dbid=' || d.dbid || ' arranque=' || TO_CHAR(i.startup_time, 'YYYY-MM-DD\"T\"HH24:MI:SS') || ' scn=' || d.current_scn FROM v\$instance i, v\$database d;" \
    | docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2> /dev/null | awk '/^hora=/ && !v {print; v=1}')
  { echo "== EVIDENCIA alumno=$est ${bd%% *} origen=t6/$1"; echo "== EVIDENCIA ${bd#* }"; cat "$2"; } \
    > "$d/$(date -u +%Y%m%dT%H%M%SZ)_t6-$1.txt"
}
dba() { docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2>&1 | grep -av '^\s*$'; }

uso() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
[ $# -ge 1 ] || uso
docker ps --format '{{.Names}}' 2>/dev/null | grep -x "$CONT" > /dev/null || { echo "El contenedor $CONT no está en marcha: docker start $CONT"; exit 2; }
h="$1"; shift
out="salidas/t6_${h}.txt"
copiar
case "$h" in
  salud)    herr salud.sql "${1:-5}" ;;
  top)      herr top.sql "${1:-5}" "${2:-elapsed}" "${3:--}" ;;
  plan)     [ -n "${1:-}" ] || { echo "Uso: t6 plan SQL_ID [hijo]   (el SQL_ID sale de: t6 top, t6 salud o la fase diagnosticar)"; exit 2; }
            herr plan.sql "$1" "${2:--}" ;;
  ash)      herr ash.sql "${1:-5}" "${2:--}" ;;
  sesiones) herr sesiones.sql "${1:--}" ;;
  base)     case "${1:-ver}" in
              registrar) [ -n "${3:-}" ] || { echo "Uso: t6 base registrar ETIQUETA SQL_ID [caso]"; exit 2; }
                         herr base.sql registrar "$2" "$3" "${4:--}" ;;
              *)         herr base.sql ver "${2:--}" - - ;;
            esac ;;
  estad)    [ -n "${1:-}" ] || { echo "Uso: t6 estad TABLA [esquema]"; exit 2; }; herr estad.sql "$1" "${2:-T6}" ;;
  indices)  [ -n "${1:-}" ] || { echo "Uso: t6 indices TABLA [esquema]"; exit 2; }; herr indices.sql "$1" "${2:-T6}" ;;
  spm)      herr spm.sql "${1:-lista}" "${2:--}" ;;
  awr)      case "${1:-lista}" in
              informe) [ -n "${3:-}" ] || { echo "Uso: t6 awr informe INI FIN   (los números salen de: t6 awr lista)"; exit 2; }
                       herr awr_informe.sql "$2" "$3" > "salidas/awr_$2_$3.txt"
                       echo "Informe AWR completo: $KIT/salidas/awr_$2_$3.txt ($(wc -l < "salidas/awr_$2_$3.txt") líneas). Lo esencial:"
                       grep -aE -A12 'Top 10 Foreground Events|SQL ordered by Elapsed Time' "salidas/awr_$2_$3.txt" | cut -c1-120 | head -40 ;;
              top|addm) [ -n "${3:-}" ] || { echo "Uso: t6 awr $1 INI FIN   (los números salen de: t6 awr lista)"; exit 2; }
                        herr awr.sql "$1" "$2" "$3" ;;
              *)       herr awr.sql "$1" 0 0 ;;
            esac ;;
  memoria)  herr memoria.sql ;;
  traza)    acc="${1:-}"; mod="${2:-}"
            case "$acc" in
              on)  [ -n "$mod" ] || { echo "Uso: t6 traza on MÓDULO [ACCIÓN]"; exit 2; }
                   printf "ALTER SESSION SET CONTAINER = FREEPDB1;\nEXEC DBMS_MONITOR.SERV_MOD_ACT_TRACE_ENABLE(service_name => 'freepdb1', module_name => '%s', action_name => %s, waits => TRUE, binds => FALSE)\nSET LINESIZE 120\nCOLUMN primary_id FORMAT A10\nCOLUMN qualifier_id1 FORMAT A14\nCOLUMN qualifier_id2 FORMAT A14\nSELECT trace_type, primary_id, qualifier_id1, qualifier_id2, waits, binds FROM dba_enabled_traces;\n" \
                     "$mod" "$( [ -n "${3:-}" ] && echo "'$3'" || echo "DBMS_MONITOR.ALL_ACTIONS" )" | dba ;;
              off) [ -n "$mod" ] || { echo "Uso: t6 traza off MÓDULO [ACCIÓN]   (la misma ACCIÓN que en traza on)"; exit 2; }
                   printf "ALTER SESSION SET CONTAINER = FREEPDB1;\nEXEC DBMS_MONITOR.SERV_MOD_ACT_TRACE_DISABLE(service_name => 'freepdb1', module_name => '%s', action_name => %s)\nSELECT 'trazas activas: ' || COUNT(*) FROM dba_enabled_traces;\n" \
                     "$mod" "$( [ -n "${3:-}" ] && echo "'$3'" || echo "DBMS_MONITOR.ALL_ACTIONS" )" | dba ;;
              tkprof)
                   idf="${2:-}"
                   dir=$(printf "SET HEADING OFF FEEDBACK OFF PAGESIZE 0\nSELECT value FROM v\$diag_info WHERE name = 'Diag Trace';\n" | dba | tr -d '[:space:]')
                   f=$(docker exec "$CONT" bash -c "cd $dir && ls -1t *${idf}*.trc 2>/dev/null | head -1")
                   [ -n "$f" ] || { echo "No hay trazas *${idf}*.trc en $dir"; exit 2; }
                   echo "   archivo de traza: $dir/$f"
                   docker exec "$CONT" bash -c "cd $dir && tkprof $f /tmp/t6/salidas_tkprof.prf sys=no sort=exeela,fchela > /dev/null" || exit 2
                   docker cp "$CONT":/tmp/t6/salidas_tkprof.prf "salidas/tkprof_${idf:-ultimo}.prf" >/dev/null
                   echo "   informe completo: $KIT/salidas/tkprof_${idf:-ultimo}.prf"
                   echo "   ---- las dos sentencias SQL más lentas (sort=exeela; se omiten los bloques PL/SQL que las llaman) ----"
                   awk 'BEGIN{RS="\\*{20,}\n"} /SQL ID:/ && !/\n(DECLARE|BEGIN|begin|declare)[ \n]/ && n<2 {n++; print}' \
                     "salidas/tkprof_${idf:-ultimo}.prf" | grep -av '^ *$' | cut -c1-120 | head -60 ;;
              *) echo "Uso: t6 traza on MÓDULO [ACCIÓN] | off MÓDULO [ACCIÓN] | tkprof [identificador]"; exit 2 ;;
            esac ;;
  fra)      printf "SET LINESIZE 120\nCOLUMN file_type FORMAT A22\nSELECT file_type, percent_space_used AS pct_usado, number_of_files AS archivos FROM v\$recovery_area_usage WHERE percent_space_used > 0;\nSELECT ROUND(space_limit/1048576) AS limite_mb, ROUND(space_used/1048576) AS usado_mb, ROUND(100*space_used/space_limit,1) AS pct FROM v\$recovery_file_dest;\n" | dba
            if [ "${1:-}" = "--liberar" ]; then
              echo "Borrando archivelogs de más de 1 hora (solo en el contenedor del aula: en producción se respaldan antes con RMAN)."
              printf "CROSSCHECK ARCHIVELOG ALL;\nDELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-1/24';\nEXIT\n" \
                | docker exec -i "$CONT" rman target / 2>&1 | grep -aE 'deleted|Deleted|RMAN-|ORA-' | tail -5
              p=$(printf "SET HEADING OFF FEEDBACK OFF\nSELECT ROUND(100*space_used/space_limit) FROM v\$recovery_file_dest;\n" | dba | tr -dc '0-9')
              if [ "${p:-0}" -ge 60 ]; then   # sigue alta: la carga reciente la llenó; se borran también los de más de 10 minutos
                echo "Sigue al ${p} %: borrando también los archivelogs de más de 10 minutos."
                printf "DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-10/1440';\nEXIT\n" \
                  | docker exec -i "$CONT" rman target / 2>&1 | grep -aE 'Deleted|RMAN-|ORA-' | tail -3
              fi
              printf "SELECT 'FRA usada: ' || ROUND(100*space_used/space_limit,1) || ' %%' FROM v\$recovery_file_dest;\n" | dba
            fi ;;
  *) uso ;;
esac 2>&1 | tee "$out"
evidencia "$h" "$out"
