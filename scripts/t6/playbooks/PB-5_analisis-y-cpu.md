# PB-5 · «Mucha CPU con poco trabajo»

| Paso | Orden | Qué mirar | Causa → acción |
|---|---|---|---|
| 1 · ¿Análisis? | `t6 top 5 ejec` · V$SYSSTAT parse count (hard) | miles de SQL_ID casi iguales, 1 ejecución cada uno | Literales: variables de enlace (C03) o CURSOR_SHARING = FORCE como puente |
| 2 · ¿Agrupables? | FORCE_MATCHING_SIGNATURE en V$SQL | muchas sentencias con la misma firma | Confirma el patrón de literales (C03) |
| 3 · ¿Funciones por fila? | `t6 plan SQL_ID` · tkprof | llamadas PL/SQL dentro del SQL | Pasar a SQL, caché escalar o WITH FUNCTION (C06) |
| 4 · ¿Recorre de más? | `t6 plan SQL_ID` | FULL con un filtro de función sobre la columna | Índice basado en función (C16, INC-612) o reescribir el predicado |
| 5 · Medir cada llamada | `t6 traza on MÓDULO ACCIÓN` → `t6 traza tkprof ID` → `t6 traza off MÓDULO ACCIÓN` | Parse frente a Execute, Misses in library cache | RB-5 (C20) |
