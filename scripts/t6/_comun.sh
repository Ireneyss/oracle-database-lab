# _comun.sh · funciones del kit del Tema 6 para los pasos .sh (se carga con: source "$(dirname "$0")/../../_comun.sh")
CONT="${CONT_NAME:-oralab-26ai}"
PWD_CASO='Casos_T6#2026x'          # la misma que DEFINE PWD_CASO en _formato.sql (cuenta T6_APP, solo para el aula)
APP="t6_app/\"${PWD_CASO}\"@//localhost:1521/freepdb1"
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
N_SES=0

titulo() { printf '\n==================== %s ====================\n' "$*"; }
paso()   { printf '\n-- %s\n' "$*"; }
espera() { printf '   (esperando %s s: %s)\n' "$1" "${2:-}"; sleep "$1"; }

# limpia la salida de SQL*Plus: sin la cabecera de versión ni el «Disconnected» del final
_limpiar() { grep -avE '^(SQL\*Plus: Release|Version [0-9]|Copyright \(c\)|Connected to:|Oracle AI Database|Disconnected from|Last Successful login time)' | cat -s; }

# sesion ETIQUETA "conexión" <<'SQL' ... SQL
#   Ejecuta el bloque en una sesión nueva de SQL*Plus DENTRO del contenedor, con el formato del kit y eco de cada orden.
#   La conexión es "/ as sysdba" o "$APP". ETIQUETA se antepone a cada línea ([DBA], [APP]...).
sesion() {
  local etq="$1" con="$2" f
  N_SES=$((N_SES + 1)); f="/tmp/t6/_ses_$$_${N_SES}.sql"
  { docker exec "$CONT" sed 's/^SET SQLPROMPT .*/SET SQLPROMPT "_USER> "/' /tmp/t6/_formato.sql; cat; echo "EXIT"; } \
    | docker exec -i "$CONT" bash -c "cat > $f"
  docker exec -e NLS_LANG "$CONT" sqlplus -L "$con" @"$f" 2>&1 | _limpiar | sed "s/^/[$etq] /"
}

# dba <<'SQL' ... SQL   · bloque corto como SYSDBA en FREEPDB1, sin eco (para preparar o medir)
dba() { { echo "SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 200 VERIFY OFF"; echo "ALTER SESSION SET CONTAINER = FREEPDB1;"; cat; echo "EXIT"; } \
        | docker exec -i -e NLS_LANG "$CONT" sqlplus -s -L / as sysdba 2>&1 | grep -av '^\s*$' | grep -av '^Session altered'; }

# carga ETQ N SEGUNDOS "llamada PL/SQL" [PAUSA]
#   Lanza N sesiones de la aplicación (T6_APP, servicio freepdb1) a la vez. Cada una repite la llamada durante SEGUNDOS
#   y la aplicación anota la latencia de cada llamada en T6.APP_LOG con la etiqueta ETQ (la «telemetría» de la web).
#   PAUSA (segundos, por defecto 0) es el «tiempo de pensar» del usuario entre dos clics.
#   Módulo «tienda_web» y acción ETQ: así se reconocen en V$SESSION, ASH y AWR.
carga() {
  local etq="$1" n="$2" seg="$3" llamada="$4" pausa="${5:-0}" s
  docker exec -i "$CONT" bash -c "cat > /tmp/t6/_carga_$etq.sql" <<SQL
SET FEEDBACK OFF HEADING OFF ECHO OFF VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE
DECLARE fin TIMESTAMP := SYSTIMESTAMP + NUMTODSINTERVAL($seg, 'SECOND'); i PLS_INTEGER := 0;
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('tienda_web', '$etq');
  t6.app.etiqueta('$etq');
  WHILE SYSTIMESTAMP < fin LOOP
    $llamada;
    IF $pausa > 0 THEN DBMS_SESSION.SLEEP($pausa); END IF;
    i := i + 1;
    IF MOD(i, 25) = 0 THEN COMMIT; END IF;
  END LOOP;
  COMMIT;
END;
/
EXIT
SQL
  printf '   carga %s: %d sesiones de la aplicación durante %d s ...\n' "$etq" "$n" "$seg"
  for ((s = 1; s <= n; s++)); do
    docker exec -e NLS_LANG "$CONT" sqlplus -s -L "$APP" @/tmp/t6/_carga_$etq.sql > "/tmp/t6_carga_${etq}_$s.log" 2>&1 &
  done
  wait
  if grep -aq 'ORA-' /tmp/t6_carga_${etq}_*.log; then echo "   !! error en la carga:"; grep -ah 'ORA-' /tmp/t6_carga_${etq}_*.log | sort | uniq -c | head -3; fi
  rm -f /tmp/t6_carga_${etq}_*.log
  printf '   carga %s terminada\n' "$etq"
}
