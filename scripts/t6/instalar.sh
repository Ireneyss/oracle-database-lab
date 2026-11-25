#!/usr/bin/env bash
# instalar.sh · deja listo el kit del Tema 6 (Laboratorio 7) y comprueba el entorno, paso a paso
#   bash scripts/t6/instalar.sh          (desde la raíz de tu repositorio oracle-database-lab)
# Qué hace: (1) comprueba Docker, el contenedor, la instancia, FREEPDB1, el esquema TIENDASUR y la FRA;
#           (2) comprueba tu código de alumno (ESTUDIANTE en config/.env); (3) crea los alias caso, t6 e incidente
#           en ~/.bashrc; (4) añade scripts/t6/salidas/ al .gitignore del repositorio. Se puede repetir sin miedo.
set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$KIT/../.." && pwd)"
CONT="${CONT_NAME:-oralab-26ai}"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
ok()   { printf '  [OK]    %s\n' "$1"; }
mal()  { printf '  [FALLO] %s\n          -> %s\n' "$1" "$2"; FALLOS=$((FALLOS + 1)); }
aviso(){ printf '  [AVISO] %s\n' "$1"; }
FALLOS=0
q() { docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2>&1 | tr -d '\r' | grep -av '^\s*$'; }

echo "== 1 · Docker y el contenedor $CONT =="
if ! command -v docker > /dev/null; then mal "no encuentro docker" "abre Docker Desktop (integración con WSL activada) y repite"; echo; exit 2; fi
docker info > /dev/null 2>&1 && ok "Docker responde" || { mal "Docker no responde" "abre Docker Desktop y espera a que diga «Engine running»"; exit 2; }
if docker ps --format '{{.Names}}' | grep -x "$CONT" > /dev/null; then ok "contenedor $CONT en marcha"
else mal "el contenedor $CONT no está en marcha" "docker start $CONT   (y espera un minuto)"; exit 2; fi

echo "== 2 · La base de datos =="
st=$(printf "SET HEADING OFF FEEDBACK OFF\nSELECT 'estado=' || status FROM v\$instance;\nSELECT 'pdb=' || open_mode FROM v\$pdbs WHERE name = 'FREEPDB1';\nSELECT 'log=' || log_mode FROM v\$database;\nSELECT 'cpu=' || value FROM v\$parameter WHERE name = 'cpu_count';\nEXIT\n" | q)
v() { echo "$st" | sed -n "s/^$1=//p" | head -1 | tr -d ' '; }
[ "$(v estado)" = OPEN ] && ok "instancia abierta" || mal "la instancia no está abierta ($(v estado))" "docker exec -it $CONT sqlplus / as sysdba  y  STARTUP"
[ "$(v pdb)" = "READWRITE" ] && ok "FREEPDB1 en READ WRITE" || mal "FREEPDB1 no está en READ WRITE ($(v pdb))" "ALTER PLUGGABLE DATABASE FREEPDB1 OPEN; (y SAVE STATE)"
[ "$(v log)" = ARCHIVELOG ] && ok "modo ARCHIVELOG (herencia del Lab 5)" || aviso "la base está en $(v log): el kit funciona igual, pero el Lab 5 la dejó en ARCHIVELOG"
ok "CPU visibles para la base: $(v cpu) (Oracle Free usa como mucho 2)"
ts=$(printf "SET HEADING OFF FEEDBACK OFF\nALTER SESSION SET CONTAINER = FREEPDB1;\nSELECT 'pedidos=' || COUNT(*) FROM tiendasur.pedido;\nSELECT 'clientes=' || COUNT(*) FROM tiendasur.cliente;\nSELECT 'banco=' || COUNT(*) FROM dba_users WHERE username = 'T6';\nEXIT\n" | q)
p=$(echo "$ts" | sed -n 's/^pedidos=//p' | tr -d ' '); c=$(echo "$ts" | sed -n 's/^clientes=//p' | tr -d ' ')
if [[ "${p:-x}" =~ ^[0-9]+$ ]] && [ "$p" -ge 1000000 ]; then ok "TIENDASUR con $p pedidos y $c clientes (Lab 5)"
else mal "no encuentro TIENDASUR.PEDIDO con 1 000 000 de pedidos" "es la carga de volumen del Lab 5 (scripts/lab5/V004 y V005). Sin ella no hay banco T6"; fi
[ "$(echo "$ts" | sed -n 's/^banco=//p' | tr -d ' ')" = 1 ] && ok "el banco T6 ya existe (caso --preparar lo devuelve a su punto de partida)" \
  || aviso "el banco T6 aún no existe: lo crea  caso --preparar  (unos 40 s)"
fra=$(printf "SET HEADING OFF FEEDBACK OFF\nSELECT ROUND(NVL(SUM(percent_space_used),0)) FROM v\$recovery_area_usage;\nEXIT\n" | q | tr -d ' ' | grep -E '^[0-9]+$' | head -1)
if [ "${fra:-0}" -lt 60 ]; then ok "zona de recuperación (FRA) al ${fra:-0} %"
else mal "la FRA está al ${fra} %: con las cargas del Tema 6 puede llenarse y congelar la base" "bash $KIT/t6.sh fra --liberar"; fi

echo "== 3 · Tu código de alumno =="
if [ -f "$REPO/config/.env" ] && [ -d "$REPO/docs" ]; then
  est=$( set -a; . "$REPO/config/.env" > /dev/null 2>&1; printf '%s' "${ESTUDIANTE:-}" )
  if [[ "$est" =~ ^E[0-9]{3}$ ]]; then ok "ESTUDIANTE=$est: tus salidas irán a docs/bitacora/lab7/evidencia/ con tu cabecera"
  else mal "config/.env no tiene ESTUDIANTE=\"E0NN\"" "ponlo con tu código de la lista de clase (Lab 6, Parte A.3) y repite"; fi
  mkdir -p "$REPO/docs/bitacora/lab7/evidencia"
else
  aviso "el kit no está en scripts/t6 de tu repositorio: funciona, pero NO genera evidencias del Lab 7"
fi

echo "== 4 · Alias en ~/.bashrc =="
chmod +x "$KIT"/*.sh 2> /dev/null
sed -i '/^# >>> kit t6 >>>/,/^# <<< kit t6 <<</d' ~/.bashrc 2> /dev/null
cat >> ~/.bashrc <<BASH
# >>> kit t6 >>>   (Laboratorio 7 · Tema 6; lo escribe scripts/t6/instalar.sh)
alias caso='bash "$KIT/caso.sh"'
alias t6='bash "$KIT/t6.sh"'
alias incidente='bash "$KIT/incidente.sh"'
# <<< kit t6 <<<
BASH
ok "alias caso, t6 e incidente → $KIT"

echo "== 5 · Git =="
if [ -d "$REPO/.git" ]; then
  grep -qx 'scripts/t6/salidas/' "$REPO/.gitignore" 2> /dev/null || echo 'scripts/t6/salidas/' >> "$REPO/.gitignore"
  ok ".gitignore ignora scripts/t6/salidas/ (las salidas sueltas; la evidencia va en docs/bitacora/lab7)"
else aviso "no es un repositorio Git: me salto el .gitignore"; fi

echo
if [ "$FALLOS" -eq 0 ]; then
  echo "LISTO. Ahora, en esta misma terminal:"
  echo "   source ~/.bashrc"
  echo "   caso --preparar        (crea el banco T6; unos 40 s)"
  echo "   caso --lista           (los 23 casos; ★ = evaluables en el Lab 7)"
else
  echo "HAY $FALLOS FALLO(S). Corrígelos y vuelve a ejecutar: bash $KIT/instalar.sh"
fi
exit "$FALLOS"
