#!/usr/bin/env bash
# caso.sh · casos prácticos del Tema 6 (Optimización) y del Laboratorio 7, en el contenedor oralab-26ai
#
#   caso --lista                  los 23 casos (★ = evaluables en el Lab 7) y sus fases
#   caso --preparar               crea o devuelve a su punto de partida el banco T6 (unos 40 s; repetible)
#   caso C03 provocar             fase 1: deja la base con el problema del enunciado
#   caso C03 entender             fase 2: lo que ve el usuario o la aplicación (el síntoma, con números)
#   caso C03 diagnosticar         fase 3: las vistas y herramientas que encuentran la causa
#   caso C03 solucionar           fase 4: la solución de referencia (inténtalo antes tú)
#   caso C03 validar              fase 5: cada línea dice OK o FALLO
#   caso C03 observar             fase 6: qué ha cambiado, la variante de examen y lo que debes retener
#   caso C03                      las seis fases seguidas
#   caso --ref C03 validar        la salida de referencia de esa fase (para comparar con la tuya)
#   caso --limpiar                borra todo lo que crea el kit (99_limpiar.sql)
#
# «caso» es el alias que crea instalar.sh; sin alias: bash scripts/t6/caso.sh ...
# Si el kit está dentro de tu repositorio (scripts/t6) y config/.env tiene ESTUDIANTE, cada fase deja además su
# evidencia, con la cabecera de alumno, en docs/bitacora/lab7/evidencia/casos/ (Laboratorio 7).
set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
cd "$KIT"
CONT="${CONT_NAME:-oralab-26ai}"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
mkdir -p salidas
FASES="provocar entender diagnosticar solucionar validar observar"
REPO="$(cd "$KIT/../.." && pwd)"
EVID=""
if [ -f "$REPO/config/.env" ] && [ -d "$REPO/docs" ]; then EVID="$REPO/docs/bitacora/lab7/evidencia/casos"; fi

copiar() {
  docker exec -u 0 "$CONT" rm -rf /tmp/t6 && docker cp "$KIT/." "$CONT":/tmp/t6 >/dev/null \
    && docker exec -u 0 "$CONT" bash -c 'chown -R oracle /tmp/t6 2>/dev/null || chmod -R a+rwX /tmp/t6' \
    || { echo "No puedo copiar el kit al contenedor $CONT (¿está en marcha? docker ps)"; exit 2; }
}
filtro() { grep -avE '^(SQL\*Plus: Release|Version [0-9]|Copyright \(c\)|Connected to:|Oracle AI Database|Disconnected from)' | cat -s; }
sqlfile() { docker exec -e NLS_LANG -w "/tmp/t6/$(dirname "$1")" "$CONT" sqlplus -L / as sysdba @"$(basename "$1")" 2>&1 | filtro; }

estudiante() { ( set -a; . "$REPO/config/.env" > /dev/null 2>&1; printf '%s' "${ESTUDIANTE:-}" ); }

cabecera() {   # las dos líneas «== EVIDENCIA» del Lab 6, con el origen del paso
  local est bd
  est=$(estudiante)
  bd=$(printf '%s\n' "SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 300" \
    "SELECT 'hora=' || TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') || ' contenedor=' || i.host_name || ' dbid=' || d.dbid || ' arranque=' || TO_CHAR(i.startup_time, 'YYYY-MM-DD\"T\"HH24:MI:SS') || ' scn=' || d.current_scn FROM v\$instance i, v\$database d;" \
    | docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2> /dev/null | awk '/^hora=/ && !v {print; v=1}')
  echo "== EVIDENCIA alumno=$est ${bd%% *} origen=t6/$1"
  echo "== EVIDENCIA ${bd#* }"
}

guardar_evidencia() {   # guardar_evidencia <archivo de salida> <origen>
  [ -n "$EVID" ] || return 0
  local est; est=$(estudiante)
  if [[ ! "$est" =~ ^E[0-9]{3}$ ]]; then
    echo "   (aviso: sin ESTUDIANTE=\"E0NN\" en config/.env esta salida no cuenta como evidencia del Lab 7)"; return 0
  fi
  mkdir -p "$EVID"
  local dest="$EVID/$(date -u +%Y%m%dT%H%M%SZ)_$(basename "$1")"
  { cabecera "$2"; cat "$1"; } > "$dest"
  echo "   evidencia: ${dest#$REPO/}"
}

ejecutar() {   # ejecutar <ruta sin extensión>  (una fase de un caso)
  local base="$1" f out id
  if   [ -f "$base.sql" ]; then f="$base.sql"
  elif [ -f "$base.sh" ];  then f="$base.sh"
  else return 1; fi
  id="$(basename "$(dirname "$base")" | cut -d_ -f1)"
  out="salidas/${id}_$(basename "$base").txt"
  echo ">> $f  ->  $out"
  if [[ "$f" == *.sql ]]; then sqlfile "$f" > "$out"; else bash "$f" > "$out" 2>&1; fi
  cat "$out"
  guardar_evidencia "$out" "${id}_$(basename "$base")"
  if [[ "$base" == */validar ]] && grep -aq '^FALLO' "$out"; then echo "!! Hay comprobaciones en FALLO: repasa la fase solucionar"; return 3; fi
  return 0
}

aviso_fra() {   # con ARCHIVELOG (Lab 5) las cargas generan redo: si la FRA se llena, el archivador se para
  local pct
  pct=$(printf 'SET HEADING OFF FEEDBACK OFF\nSELECT ROUND(NVL(SUM(percent_space_used),0)) FROM v$recovery_area_usage;\nEXIT\n' \
       | docker exec -i "$CONT" sqlplus -s -L / as sysdba 2>/dev/null | tr -d ' \r' | grep -E '^[0-9]+$' | head -1)
  [ -n "$pct" ] && [ "$pct" -ge 80 ] && cat <<MSG
AVISO: la zona de recuperación (FRA) está al ${pct} %. Si llega al 100 % el archivador se para y la base se congela.
Libérala antes de seguir:   bash $KIT/t6.sh fra --liberar
MSG
  return 0
}

comprobar_base() {
  docker ps --format '{{.Names}}' 2>/dev/null | grep -x "$CONT" > /dev/null || {
    echo "El contenedor $CONT no está en marcha. Arráncalo con:  docker start $CONT   (y espera 1 minuto)"; exit 2; }
  local st
  st=$(printf 'SET HEADING OFF FEEDBACK OFF\nSELECT status FROM v$instance;\nEXIT\n' \
       | docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2>&1 | tr -d ' \r' | grep -E 'OPEN|MOUNTED|STARTED|ORA-01034' | head -1)
  case "$st" in
    OPEN) aviso_fra; return 0 ;;
    *ORA-01034*) cat <<MSG
La instancia de Oracle está PARADA: el contenedor funciona, la base no. Arráncala (una orden cada vez):
   docker exec -it $CONT sqlplus / as sysdba
   STARTUP
   SELECT name, open_mode FROM v\$pdbs;      (FREEPDB1 debe estar en READ WRITE)
Si se queda en «Database mounted.» con ORA-19809/ORA-16038, la FRA está llena: bash $KIT/t6.sh fra --liberar
MSG
      exit 2 ;;
    STARTED|MOUNTED) echo "La instancia está en $st (no abierta). Entra en sqlplus y ejecuta: ALTER DATABASE OPEN;"; exit 2 ;;
    *) echo "No puedo consultar la instancia en $CONT (respuesta: ${st:-vacía}). Comprueba: docker exec -it $CONT sqlplus / as sysdba"; exit 2 ;;
  esac
  local banco
  banco=$(printf 'SET HEADING OFF FEEDBACK OFF\nALTER SESSION SET CONTAINER=FREEPDB1;\nSELECT COUNT(*) FROM dba_users WHERE username = '"'"'T6'"'"';\nEXIT\n' \
       | docker exec -i "$CONT" sqlplus -s -L / as sysdba 2>/dev/null | tr -d ' \r' | grep -E '^[0-9]+$' | tail -1)
  [ "${banco:-0}" = 1 ] || [ "${PREPARANDO:-0}" = 1 ] || { echo "Falta el banco T6. Ejecuta primero:  caso --preparar"; exit 2; }
}

dir_caso() { ls -d 6.*/"$1"_* 2>/dev/null | head -1; }
estrella() { awk -F'\t' -v c="$1" '$1 == c {print $3}' casos.tsv; }

case "${1:---lista}" in
  --lista)
    printf '%-4s %-4s %s\n' "Caso" "★" "Sección · título · (fases)"
    awk -F'\t' '!/^#/ {printf "%-4s %-4s %s · %s%s\n", $1, ($3=="★"?"★":""), $2, $5, ($7!=""?"  [" $7 "]":"")}' casos.tsv
    echo; echo "Fases de cada caso: $FASES   ·   ★ = evaluable en el Laboratorio 7; el resto, preparación de la certificación" ;;
  --preparar) PREPARANDO=1 comprobar_base; copiar; echo ">> 00_preparar.sql  (unos 40 s)"; sqlfile 00_preparar.sql | tee salidas/00_preparar.txt
              guardar_evidencia salidas/00_preparar.txt 00_preparar ;;
  --limpiar)  comprobar_base; copiar; echo ">> 99_limpiar.sql";  sqlfile 99_limpiar.sql  | tee salidas/99_limpiar.txt ;;
  --ref)
    f="referencia/${2:-}_${3:-}.txt"
    [ -f "$f" ] && cat "$f" || echo "No hay salida de referencia $f (casos: caso --lista; fases: $FASES)" ;;
  C[0-9][0-9])
    d=$(dir_caso "$1"); [ -n "$d" ] || { echo "No hay ningún caso «$1». Usa: caso --lista"; exit 2; }
    comprobar_base
    copiar
    printf '== Caso %s %s· %s\n' "$1" "$( [ "$(estrella "$1")" = "★" ] && echo '★ ' )" "$(awk -F'\t' -v c="$1" '$1 == c {print $5}' casos.tsv)"
    if [ -n "${2:-}" ]; then
      ejecutar "$d/$2" || { rc=$?; [ $rc -eq 1 ] && echo "El caso $1 no tiene la fase «$2» (fases: $(ls "$d" | sed 's/\.[a-z]*$//' | tr '\n' ' '))"; exit $rc; }
    else
      for p in $FASES; do ejecutar "$d/$p"; done
    fi ;;
  *) echo "Uso: caso --lista | --preparar | Cnn [fase] | --ref Cnn fase | --limpiar   (fases: $FASES)"; exit 2 ;;
esac
