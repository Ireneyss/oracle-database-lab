#!/usr/bin/env bash
# scripts/lab5/12-reto-fra-delete.sh — reto de la Parte M: cuánto crece la FRA al repetir 12-undo-y-redo.sql
# Uso: bash scripts/lab5/12-reto-fra-delete.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh
sql() { docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba; }
FOTO="SET HEADING OFF FEEDBACK OFF PAGESIZE 0
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT space_used FROM v\$recovery_file_dest;
SELECT MAX(sequence#) FROM v\$archived_log;
EXIT"
echo "== 1. Antes: se archiva el grupo actual para partir de un punto limpio =="
read -r USADO0 SEQ0 <<< "$(echo "$FOTO" | sql | xargs)"
echo "FRA usada: $USADO0 bytes · último archivado: $SEQ0"
echo "== 2. 12-undo-y-redo.sql otra vez =="
bash scripts/ops/sysdba.sh scripts/lab5/12-undo-y-redo.sql | grep -E 'INSERT|UPDATE|DELETE|ROLLBACK'
echo "== 3. Después: ALTER SYSTEM ARCHIVE LOG CURRENT =="
read -r USADO1 SEQ1 <<< "$(echo "$FOTO" | sql | xargs)"
echo "FRA usada: $USADO1 bytes · último archivado: $SEQ1"
echo "Crecimiento de la FRA: $(( (USADO1 - USADO0) / 1024 )) KB en $((SEQ1 - SEQ0)) archivado(s)"
printf "SET LINESIZE 120 PAGESIZE 50 FEEDBACK OFF\nSELECT sequence#, ROUND(blocks * block_size / 1024) AS kb FROM v\$archived_log WHERE sequence# > %s AND dest_id = 1 ORDER BY sequence#;\nEXIT\n" "$SEQ0" | sql
