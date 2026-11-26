#!/usr/bin/env bash
# scripts/lab7/09-verificacion-final.sh — comprobación automática del estado final del Lab 7 (Tema 6, Optimización)
# Uso: bash scripts/lab7/09-verificacion-final.sh      (desde la raíz del repositorio, al terminar la Parte G)
set -uo pipefail
source scripts/deployment/env/00-config.sh
source scripts/ops/cabecera.sh "$(basename "$0" .sh)" || exit 2   # cabecera de evidencia (alumno, hora, contenedor, SCN)
EVID_LAB7="docs/bitacora/lab7/evidencia"
KIT="scripts/t6"
ESTRELLA="C01 C03 C04 C07 C08 C12 C13 C14 C17 C18"
FASES="provocar entender diagnosticar solucionar validar observar"
fallos=0
ok()    { printf '  [OK]    %s\n' "$1"; }
fallo() { printf '  [FALLO] %s  -> repasa %s\n' "$1" "$2"; fallos=$((fallos + 1)); }
comprobar() { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else fallo "$1: hay '$2', se esperaba '$3'" "$4"; fi; }
ultimo() { ls -1 "$1"/*_"$2".txt 2> /dev/null | sort | tail -1; }   # la evidencia más reciente de un paso
ESTUDIANTE=$(set -a; . config/.env > /dev/null 2>&1; printf '%s' "${ESTUDIANTE:-}")
VALORES=$(docker exec -i -e NLS_LANG=AMERICAN_AMERICA.AL32UTF8 "$CONT_NAME" sqlplus -s -L / as sysdba <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 300
SELECT 'cdb=' || open_mode || '/' || log_mode FROM v$database;
SELECT 'pdb=' || open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
SELECT 'fra=' || ROUND(NVL(SUM(percent_space_used), 0)) FROM v$recovery_area_usage;
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT 'banco=' || COUNT(*) FROM dba_users WHERE username IN ('T6', 'T6_APP');
SELECT 'linea_base=' || COUNT(*) FROM t6.linea_base;
SELECT 'trazas=' || COUNT(*) FROM dba_enabled_traces;
SELECT 'invalidos=' || COUNT(*) FROM dba_objects WHERE owner = 'T6' AND status = 'INVALID';
SELECT 'param_pdb=' || COUNT(*) FROM v$system_parameter WHERE isdefault = 'FALSE' AND ismodified <> 'FALSE'
   AND name IN ('optimizer_index_cost_adj', 'optimizer_mode', 'cursor_sharing', 'optimizer_features_enable');
EXIT
SQL
)
val() { echo "$VALORES" | sed -n "s/^$1=//p" | awk 'NR==1' | tr -d '[:space:]'; }

echo "== Parte A · Punto de partida =="
BK=$(ls -d backups/*_lab7-inicio 2>/dev/null | tail -1)
if [ -n "$BK" ] && (cd "$BK" && sha256sum -c --quiet SHA256SUMS); then ok "copia $BK íntegra"; else fallo "no hay copia lab7-inicio íntegra" "Parte A.3"; fi
comprobar "CDB abierta y en ARCHIVELOG (herencia del Lab 5)" "$(val cdb)" "READWRITE/ARCHIVELOG" "Lab 5, Parte L"
comprobar "FREEPDB1 abierta" "$(val pdb)" "READWRITE" "Parte A"
for f in caso.sh t6.sh incidente.sh instalar.sh casos.tsv; do
  [ -f "$KIT/$f" ] && ok "kit: $KIT/$f" || fallo "falta $KIT/$f" "Parte A.1 (descomprimir el zip en scripts/)"
done
comprobar "banco T6 (esquemas T6 y T6_APP)" "$(val banco)" 2 "Parte A.5 (caso --preparar)"
if [ "$(val fra)" -lt 80 ] 2>/dev/null; then ok "FRA al $(val fra) %"; else fallo "FRA al $(val fra) %" "t6 fra --liberar"; fi

echo "== Partes B a F · Los 10 casos ★ (seis fases cada uno y validar sin FALLO) =="
for c in $ESTRELLA; do
  falta=""
  for p in $FASES; do [ -n "$(ultimo "$EVID_LAB7/casos" "${c}_$p")" ] || falta="$falta $p"; done
  v=$(ultimo "$EVID_LAB7/casos" "${c}_validar")
  if [ -n "$falta" ]; then fallo "$c: faltan evidencias de$falta" "caso $c <fase>"
  elif grep -aq '^FALLO' "$v" || ! grep -aq '^OK' "$v"; then fallo "$c: la última validación tiene FALLO ($(basename "$v"))" "caso $c solucionar y caso $c validar"
  else ok "$c: seis fases y validación correcta ($(grep -ac '^OK' "$v") OK)"; fi
done
if [ "$(val linea_base)" -ge 2 ] 2>/dev/null; then ok "línea base registrada en T6.LINEA_BASE ($(val linea_base) medidas)"
else fallo "T6.LINEA_BASE tiene $(val linea_base) medidas (se esperan al menos 2)" "C01 (t6 base registrar)"; fi

echo "== Parte G · Tus tres incidentes =="
MIOS=$(ESTUDIANTE="$ESTUDIANTE" bash "$KIT/incidente.sh" --mios 2> /dev/null | grep -ao 'INC-6[0-9][0-9]' | sort -u)
[ -n "$MIOS" ] || fallo "no puedo calcular tus incidentes" "ESTUDIANTE en config/.env"
for i in $MIOS; do
  r=$(ultimo "$EVID_LAB7/incidentes" "${i}_romper"); v=$(ultimo "$EVID_LAB7/incidentes" "${i}_verificar")
  if [ -z "$r" ]; then fallo "$i: no hay evidencia de romper" "incidente $i romper"
  elif [ -z "$v" ]; then fallo "$i: no hay evidencia de verificar" "incidente $i verificar"
  elif [ "$v" \< "$r" ]; then fallo "$i: la última verificación es anterior a la última rotura" "incidente $i verificar"
  elif grep -aq '^FALLO' "$v" || ! grep -aq "^OK    Incidente $i roto para $ESTUDIANTE" "$v"; then fallo "$i: la última verificación no está toda en OK" "el playbook del incidente"
  else ok "$i: roto y arreglado ($(grep -ac '^OK' "$v") OK, $(basename "$v"))"; fi
done
comprobar "sin trazas activas olvidadas" "$(val trazas)" 0 "RB-5 (t6 traza off MÓDULO ACCIÓN)"
comprobar "sin parámetros del optimizador cambiados en la PDB" "$(val param_pdb)" 0 "INC-610 / PB-3"
comprobar "objetos inválidos en T6" "$(val invalidos)" 0 "caso --preparar"

echo "== Parte H · Respuestas, Git y uso de IA =="
R=docs/bitacora/lab7-respuestas.md
if [ -f "$R" ]; then
  ok "respuestas en $R"
  for t in C01 C03 C04 C07 C08 C12 C13 C14 C17 C18 "Incidente 1" "Incidente 2" "Incidente 3" "Reflexión"; do
    grep -aq "^## .*$t" "$R" || fallo "falta el apartado «$t» en $R" "docs/plantillas/lab7-respuestas.md"
  done
  for i in $MIOS; do grep -aq "$i" "$R" || fallo "$R no menciona tu incidente $i" "Parte G"; done
  grep -aq 'INC-6NN' "$R" && fallo "$R aún tiene «INC-6NN» sin sustituir" "Parte G"
else fallo "faltan las respuestas ($R)" "Parte H (copia docs/plantillas/lab7-respuestas.md)"; fi
if git ls-files --error-unmatch config/.env > /dev/null 2>&1; then fallo "config/.env está en Git" ".gitignore"; else ok "config/.env fuera de Git"; fi
if git ls-files | grep '^scripts/t6/salidas/' > /dev/null; then fallo "hay salidas sueltas de scripts/t6/salidas en Git" "git rm -r --cached scripts/t6/salidas"; else ok "scripts/t6/salidas fuera de Git"; fi
if git ls-files | grep -E '^backups/|\.(ora|dbf|ctl|arc|bkp|trc|prf)$' > /dev/null; then fallo "hay archivos de la base o trazas en Git" ".gitignore"; else ok "ningún archivo de la base ni traza en Git"; fi
if [ -f login.sql ] && grep -q "DEFINE ESTUDIANTE = $ESTUDIANTE\$" login.sql; then ok "login.sql con tu código (prompt de SQLcl)"
else fallo "falta login.sql o no lleva tu código" "bash scripts/ops/alumno.sh"; fi
if command -v python3 > /dev/null; then
  python3 scripts/ops/autoria.py --lab 7 --repo . --alumno "$ESTUDIANTE" --desde lab6-final
  fallos=$((fallos + $?))
else fallo "falta python3 para comprobar docs/bitacora/lab7-ia.md y las cabeceras" "sudo apt install -y python3"; fi
echo
if [ "$fallos" -eq 0 ]; then echo "RESULTADO: TODO OK. Lab 7 listo para entregar."; else echo "RESULTADO: $fallos FALLO(S). Corrige antes de abrir el PR."; fi
exit "$fallos"
