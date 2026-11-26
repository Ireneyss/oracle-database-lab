-- C02 · observar · las dos cargas lado a lado, y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN redo_kb FORMAT 999,990
SELECT etq, filas_por_commit, ms_total, cpu_ms, commits, esperas_lfs, ms_lfs, ROUND(redo_bytes / 1024) AS redo_kb
  FROM t6.c02_medida ORDER BY filas_por_commit;
PROMPT == Lo que debes retener ==
PROMPT 1. DB time = DB CPU + esperas. Si la CPU explica poco del tiempo, la respuesta está en los eventos de espera.
PROMPT 2. «log file sync» se paga en cada COMMIT: se arregla con transacciones del tamaño del negocio, no con discos.
PROMPT 3. Variante de examen: COMMIT WRITE BATCH NOWAIT también lo reduce, pero renuncia a la durabilidad inmediata.
PROMPT    Un DBA no la propone sin que el negocio acepte perder las últimas confirmaciones si cae la instancia.
PROMPT 4. Dentro de un bucle PL/SQL Oracle no espera en cada COMMIT (optimización de PL/SQL): mide siempre como
PROMPT    trabaja la aplicación real (aquí, COMMIT WRITE WAIT), o el laboratorio te dará una cifra que producción no verá.
EXIT
