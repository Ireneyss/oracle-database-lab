-- C03 · observar · el parche de emergencia: CURSOR_SHARING = FORCE (sin tocar la aplicación) y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SESSION SET cursor_sharing = FORCE;
PROMPT == La versión de LITERALES otra vez, ahora con CURSOR_SHARING = FORCE en la sesión ... ==
@@_medir FORCE
ALTER SESSION SET cursor_sharing = EXACT;
SELECT modo, llamadas, ms_total, hard_parses, ROUND(ms_total / llamadas, 3) AS ms_por_ficha FROM t6.c03_medida ORDER BY ms_total DESC;
PROMPT == El texto que ha guardado Oracle: el literal se ha convertido en una variable del sistema ==
SELECT sql_id, executions, SUBSTR(sql_text, 1, 90) AS sql_text FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_ficha */%SYS_B_0%';
PROMPT == Lo que debes retener ==
PROMPT 1. Síntoma de literales: CPU y «hard parse elapsed time» altos, miles de SQL_ID con 1 ejecución y la misma FIRMA.
PROMPT 2. La cura está en la aplicación: variables de enlace. Menos CPU, menos latches y una shared pool estable.
PROMPT 3. CURSOR_SHARING = FORCE es un parche (se pone por sesión, servicio o PDB): alivia, pero cambia todos los literales
PROMPT    (también los que dan selectividad al optimizador) y oculta el defecto. Se documenta y se retira cuando llega la cura.
EXIT
