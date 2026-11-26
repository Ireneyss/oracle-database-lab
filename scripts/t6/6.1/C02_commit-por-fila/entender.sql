-- C02 · entender · el síntoma: la carga nocturna tarda mucho para lo poco que hace (20 000 filas pequeñas)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == Lo que tardó la carga y cuánto trabajo útil hizo ==
SELECT etq, ms_total, cpu_ms, ms_total - cpu_ms AS ms_no_cpu, ROUND(100 * (ms_total - cpu_ms) / ms_total) AS pct_no_cpu,
       ROUND(20000 / (ms_total / 1000)) AS filas_seg
  FROM t6.c02_medida WHERE etq = 'POR_FILA';
PROMPT -- Lectura: si la sesión no estaba en CPU, estaba ESPERANDO algo. DB time = DB CPU + esperas: ¿cuál?
EXIT
