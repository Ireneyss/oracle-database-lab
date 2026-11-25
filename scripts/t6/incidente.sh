#!/usr/bin/env bash
# incidente.sh · banco de incidentes del Tema 6 (Laboratorio 7): la base se rompe con TU semilla y tú la arreglas
#
#   incidente --lista                 los 8 incidentes, su playbook y los casos que los preparan
#   incidente --mios                  los 3 incidentes que te tocan (salen de tu código E0NN de config/.env)
#   incidente INC-6NN romper          deja la base con el problema (con detalles que dependen de tu semilla)
#   incidente INC-6NN pistas          el ticket, lo que ve el usuario y por dónde empezar (sin la solución)
#   incidente INC-6NN verificar       cada línea dice OK o FALLO; deja la evidencia con tu cabecera
#
# «incidente» es el alias que crea instalar.sh; sin alias: bash scripts/t6/incidente.sh ...
# Requisitos: el banco T6 (caso --preparar) y ESTUDIANTE="E0NN" en config/.env (o la variable ESTUDIANTE).
# Se arreglan con la caja de herramientas (t6 ...), los playbooks (playbooks/) y lo aprendido en los casos.
set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
cd "$KIT"
CONT="${CONT_NAME:-oralab-26ai}"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
mkdir -p salidas
REPO="$(cd "$KIT/../.." && pwd)"
TSV="incidentes/incidentes.tsv"

estudiante() {
  local e="${ESTUDIANTE:-}"
  [ -z "$e" ] && [ -f "$REPO/config/.env" ] && e=$( set -a; . "$REPO/config/.env" > /dev/null 2>&1; printf '%s' "${ESTUDIANTE:-}" )
  printf '%s' "$e"
}
EST="$(estudiante)"
semilla() { [[ "$EST" =~ ^E([0-9]{3})$ ]] && echo $((10#${BASH_REMATCH[1]})); }
mios() {   # los 3 incidentes de este alumno: orden por md5(alumno+incidente), los 3 primeros
  awk -F'\t' '!/^#/ {print $1}' "$TSV" | while read -r i; do printf '%s %s\n' "$(printf '%s%s' "$EST" "$i" | md5sum | cut -c1-8)" "$i"; done \
    | sort | head -3 | awk '{print $2}' | sort
}
carpeta() { awk -F'\t' -v i="$1" '$1 == i {print "incidentes/" $2}' "$TSV"; }

copiar() {
  docker exec -u 0 "$CONT" rm -rf /tmp/t6 && docker cp "$KIT/." "$CONT":/tmp/t6 >/dev/null \
    && docker exec -u 0 "$CONT" bash -c 'chown -R oracle /tmp/t6 2>/dev/null || chmod -R a+rwX /tmp/t6' \
    || { echo "No puedo copiar el kit al contenedor $CONT (¿está en marcha? docker ps)"; exit 2; }
}
filtro() { grep -avE '^(SQL\*Plus: Release|Version [0-9]|Copyright \(c\)|Connected to:|Oracle AI Database|Disconnected from)' | cat -s; }
cabecera() {
  local bd
  bd=$(printf '%s\n' "SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 300" \
    "SELECT 'hora=' || TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') || ' contenedor=' || i.host_name || ' dbid=' || d.dbid || ' arranque=' || TO_CHAR(i.startup_time, 'YYYY-MM-DD\"T\"HH24:MI:SS') || ' scn=' || d.current_scn FROM v\$instance i, v\$database d;" \
    | docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2> /dev/null | awk '/^hora=/ && !v {print; v=1}')
  echo "== EVIDENCIA alumno=$EST ${bd%% *} origen=t6/$1"
  echo "== EVIDENCIA ${bd#* }"
}

uso() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
case "${1:---lista}" in
  --lista)
    printf '%-8s %-5s %-5s %-12s %s\n' "Id" "PB" "RB" "Casos" "Ticket"
    awk -F'\t' '!/^#/ {printf "%-8s %-5s %-5s %-12s %s\n", $1, $4, $5, $6, $3}' "$TSV"
    echo; echo "Playbooks: playbooks/PB-*.md · Runbooks: runbooks/RB-*.md · Tus 3 incidentes: incidente --mios"; exit 0 ;;
  --mios)
    [ -n "$(semilla)" ] || { echo "Falta tu código: ESTUDIANTE=\"E0NN\" en config/.env (o ESTUDIANTE=E0NN incidente --mios)"; exit 2; }
    echo "Alumno $EST (semilla $(semilla)). Tus incidentes del Laboratorio 7:"
    for i in $(mios); do awk -F'\t' -v i="$i" '$1 == i {printf "   %s  %s   (playbook %s, runbook %s)\n", $1, $3, $4, $5}' "$TSV"; done
    exit 0 ;;
  INC-6[0-9][0-9]) ;;
  *) uso ;;
esac
inc="$1"; fase="${2:-}"
d="$(carpeta "$inc")"; [ -n "$d" ] && [ -d "$d" ] || { echo "No hay ningún incidente «$inc». Usa: incidente --lista"; exit 2; }
S="$(semilla)"; [ -n "$S" ] || { echo "Falta tu código: ESTUDIANTE=\"E0NN\" en config/.env. Sin él, el incidente no se puede personalizar."; exit 2; }
docker ps --format '{{.Names}}' 2>/dev/null | grep -x "$CONT" > /dev/null || { echo "El contenedor $CONT no está en marcha: docker start $CONT"; exit 2; }
case "$fase" in
  pistas) cat "$d/pistas.md"; exit 0 ;;
  romper|verificar) ;;
  *) echo "Uso: incidente $inc romper | pistas | verificar"; exit 2 ;;
esac
mios | grep -x "$inc" > /dev/null || echo "   (aviso: $inc no es uno de tus 3 incidentes; puedes practicarlo, pero no cuenta: incidente --mios)"
copiar
out="salidas/${inc}_${fase}.txt"
{
  echo "== $inc · $fase · alumno $EST · semilla $S"
  if [ -f "$d/$fase.sql" ]; then
    docker exec -e NLS_LANG -w "/tmp/t6/$d" "$CONT" sqlplus -L -s / as sysdba @"$fase.sql" "$S" "$EST" 2>&1 | filtro
  else
    ESTUDIANTE="$EST" SEMILLA="$S" bash "$d/$fase.sh" 2>&1
  fi
} | tee "$out"
if [ -f "$REPO/config/.env" ] && [ -d "$REPO/docs" ]; then
  ev="$REPO/docs/bitacora/lab7/evidencia/incidentes"; mkdir -p "$ev"
  dest="$ev/$(date -u +%Y%m%dT%H%M%SZ)_${inc}_${fase}.txt"
  { cabecera "${inc}_${fase}"; cat "$out"; } > "$dest"; echo "   evidencia: ${dest#$REPO/}"
fi
[ "$fase" = verificar ] && grep -aq '^FALLO' "$out" && { echo "!! Aún hay comprobaciones en FALLO: sigue el playbook"; exit 3; }
[ "$fase" = romper ] && echo "   Roto. Lee el ticket:  incidente $inc pistas"
exit 0
