-- C04 · entender · el síntoma: el informe tarda, y el usuario solo mira la primera página (las 100 primeras filas)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN mb_temp FORMAT 9990.0
PROMPT == Lo que costó el informe ==
SELECT modo, filas, ms, temp_escritos, ROUND(temp_escritos * 8192 / 1048576, 1) AS mb_temp FROM t6.c04_medida WHERE modo = 'LEGADO';
PROMPT -- Lectura: escribió en TEMP (disco) para ORDENAR. Una ordenación es bloqueante: hasta tener la última fila
PROMPT -- no puede devolver la primera. Si no cabe en memoria, va a disco y vuelve a leerla.
EXIT
