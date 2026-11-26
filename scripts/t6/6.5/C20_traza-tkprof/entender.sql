-- C20 · entender · lo que ve la web: la mayoría de las llamadas van bien y algunas tardan mucho más («a tirones»)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
SELECT etq, COUNT(*) AS llamadas, ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ms), 2) AS p50_ms,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ms), 2) AS p99_ms, ROUND(MAX(ms), 1) AS max_ms
  FROM t6.app_log WHERE etq = 'C20_ALTA' GROUP BY etq;
PROMPT -- Lectura: la mediana es buena y la cola (p99, máximo) no. Con una media no se vería. ¿Qué llamadas son las lentas?
PROMPT -- ASH muestrea una vez por segundo y se pierde lo que dura milisegundos: la traza registra TODAS las llamadas.
EXIT
