#!/usr/bin/env bash
# scripts/lab5/04-reto-curva.sh — reto de la Parte E: dibuja en SVG (escala logarítmica) la curva del punto de equilibrio
# a partir de la sección 3 de la evidencia 04. Uso: bash scripts/lab5/04-reto-curva.sh [evidencia_04] [salida.svg]
set -euo pipefail
source scripts/deployment/env/00-config.sh
EVI="${1:-$(ls -t "$EVID_LAB5"/script/*_04-agrupamiento-equilibrio.script.log | head -1)}"
OUT="${2:-docs/bitacora/lab5/curva-punto-equilibrio.svg}"
# Filas de datos: "k %  filas  bueno  malo  tabla  elección..."
grep -E '^[0-9.]+ %' "$EVI" | awk '
function lx(k) { return X0 + (log(k) / log(10) + 2) / 4 * W }          # k de 0,01 % a 100 %: 4 décadas
function ly(v) { return Y0 + H - (log(v) / log(10)) / 7 * H }           # lecturas de 1 a 10^7
BEGIN { X0 = 80; Y0 = 40; W = 620; H = 340; n = 0 }
{ k[n] = $1; bueno[n] = $4; malo[n] = $5; tabla[n] = $6; opt[n] = ($7 == "índice" || $7 ~ /ndice/) ? "I" : "F"; n++ }
END {
  printf "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"760\" height=\"460\" viewBox=\"0 0 760 460\" font-family=\"sans-serif\" font-size=\"12\">\n"
  printf "<rect width=\"760\" height=\"460\" fill=\"white\"/>\n"
  printf "<text x=\"380\" y=\"22\" text-anchor=\"middle\" font-size=\"15\">Punto de equilibrio en TIENDASUR.PEDIDO (lecturas lógicas, escala log-log)</text>\n"
  # rejilla
  for (d = -2; d <= 2; d++) { x = lx(10 ^ d); printf "<line x1=\"%.1f\" y1=\"%d\" x2=\"%.1f\" y2=\"%d\" stroke=\"#ddd\"/>\n", x, Y0, x, Y0 + H
    printf "<text x=\"%.1f\" y=\"%d\" text-anchor=\"middle\">%s %%</text>\n", x, Y0 + H + 18, (d < 0 ? sprintf("%.2g", 10 ^ d) : 10 ^ d) }
  for (e = 0; e <= 7; e++) { y = ly(10 ^ e); printf "<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#ddd\"/>\n", X0, y, X0 + W, y
    printf "<text x=\"%d\" y=\"%.1f\" text-anchor=\"end\">1e%d</text>\n", X0 - 6, y + 4, e }
  printf "<text x=\"380\" y=\"%d\" text-anchor=\"middle\">k = porcentaje de filas pedidas</text>\n", Y0 + H + 40
  printf "<text x=\"20\" y=\"%d\" transform=\"rotate(-90 20 %d)\" text-anchor=\"middle\">lecturas lógicas</text>\n", Y0 + H / 2, Y0 + H / 2
  # zona en la que el optimizador elige el índice malo
  for (i = 0; i < n; i++) if (opt[i] == "I") last = i
  printf "<rect x=\"%d\" y=\"%d\" width=\"%.1f\" height=\"%d\" fill=\"#e8f0ff\"/>\n", X0, Y0, (lx(k[last]) + lx(k[last + 1])) / 2 - X0, H
  printf "<text x=\"%d\" y=\"%d\" fill=\"#3060c0\">el optimizador elige el índice (CF malo)</text>\n", X0 + 6, Y0 + 16
  split("tabla bueno malo", serie, " "); color["tabla"] = "#222"; color["bueno"] = "#2a9d4b"; color["malo"] = "#d1495b"
  etiqueta["tabla"] = "tabla entera (recorrido completo)"; etiqueta["bueno"] = "índice CF bueno (IX_PED_FECHA)"; etiqueta["malo"] = "índice CF malo (IX_PED_CLIENTE)"
  for (s = 1; s <= 3; s++) { nom = serie[s]; pts = ""
    for (i = 0; i < n; i++) { v = (nom == "tabla") ? tabla[i] : (nom == "bueno") ? bueno[i] : malo[i]; pts = pts sprintf("%.1f,%.1f ", lx(k[i]), ly(v)) }
    printf "<polyline fill=\"none\" stroke=\"%s\" stroke-width=\"2\" points=\"%s\"/>\n", color[nom], pts
    printf "<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"%s\" stroke-width=\"3\"/><text x=\"%d\" y=\"%d\">%s</text>\n", 440, 300 + s * 18, 465, 300 + s * 18, color[nom], 470, 304 + s * 18, etiqueta[nom] }
  # cruces con la tabla (interpolación logarítmica)
  for (s = 1; s <= 2; s++) { nom = (s == 1) ? "malo" : "bueno"
    for (i = 1; i < n; i++) { a = (nom == "malo") ? malo[i - 1] : bueno[i - 1]; b = (nom == "malo") ? malo[i] : bueno[i]
      if (a < tabla[i - 1] && b >= tabla[i]) { f = (log(tabla[i]) - log(a)) / (log(b) - log(a)); kc = exp(log(k[i - 1]) + f * (log(k[i]) - log(k[i - 1])))
        printf "<circle cx=\"%.1f\" cy=\"%.1f\" r=\"5\" fill=\"%s\"/>\n", lx(kc), ly(tabla[i]), color[nom]
        printf "<text x=\"%.1f\" y=\"%.1f\" fill=\"%s\" text-anchor=\"%s\">cruce ~%.2g %%</text>\n", lx(kc) + (nom == "malo" ? 8 : -8), ly(tabla[i]) - 10, color[nom], (nom == "malo" ? "start" : "end"), kc
        print "cruce " nom " ~" kc " %" > "/dev/stderr" } } }
  print "</svg>" }' > "$OUT"
echo "Gráfico generado: $OUT"
