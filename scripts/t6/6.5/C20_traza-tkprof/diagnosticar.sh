#!/usr/bin/env bash
# C20 · diagnosticar · tkprof sobre la traza del módulo: las sentencias ordenadas por tiempo de ejecución y de lectura
# Equivale a:  t6 traza tkprof C20
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$KIT6/t6.sh" traza tkprof C20
f="$KIT6/salidas/tkprof_C20.prf"
[ -f "$f" ] || exit 2
echo
echo "   ---- análisis (parse) frente a ejecuciones, en todo el archivo ----"
grep -aE '^(Parse|Execute|Fetch|total) ' "$f" | tail -4
grep -aE 'Misses in library cache during parse' "$f" | sort | uniq -c | sort -rn | head -3
echo "   -- Lectura: arriba sale el panel de ventas (pocas ejecuciones, mucho tiempo cada una): son los «tirones»."
echo "   -- La segunda es UNA de las miles de fichas: con literales, cada ficha es una sentencia distinta en el informe,"
echo "   -- y miles de «Misses in library cache during parse: 1» = un análisis completo por ficha (caso C03)."
