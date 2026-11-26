-- C04 · diagnosticar · ¿por qué no cupo en memoria? El área de trabajo (V$SQL_WORKAREA) y la configuración heredada
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN etiqueta FORMAT A10
COLUMN trigger_body FORMAT A80
COLUMN mb_optimo FORMAT 9990.0
COLUMN mb_temp FORMAT 9990.0
PROMPT == 1 · El área de trabajo de la ordenación: cuánta memoria necesitaba, cuánta usó y cómo se ejecutó ==
SELECT REGEXP_SUBSTR(s.sql_text, 't6_informe_(\w+)', 1, 1, NULL, 1) AS etiqueta, w.operation_type,
       ROUND(w.estimated_optimal_size / 1048576, 1) AS mb_optimo, ROUND(w.last_memory_used / 1024) AS kb_usados,
       w.last_execution, ROUND(w.last_tempseg_size / 1048576, 1) AS mb_temp, w.policy
  FROM v$sql_workarea w JOIN v$sql s ON s.sql_id = w.sql_id AND s.child_number = w.child_number
 WHERE s.sql_text LIKE 'SELECT /*+ t6_informe%';
PROMPT == 2 · ¿Por qué política MANUAL? Lo que se ejecuta al iniciar sesión la cuenta de informes ==
SELECT owner, trigger_name, triggering_event, status FROM dba_triggers WHERE owner = 'T6' AND triggering_event LIKE 'LOGON%';
SET LONG 400
SELECT trigger_body FROM dba_triggers WHERE owner = 'T6' AND trigger_name = 'C04_LEGADO';
PROMPT == 3 · Lo que la instancia asigna con la PGA automática (lo que el disparador anula) ==
SELECT name, ROUND(value / 1048576) AS mb FROM v$pgastat WHERE name IN ('aggregate PGA target parameter', 'global memory bound');
PROMPT -- Lectura: OPTIMAL = en memoria; ONE PASS = una vuelta a TEMP; MULTI-PASS = varias (lo peor).
PROMPT -- Con POLICY = MANUAL la sesión usa SORT_AREA_SIZE (1 MB) aunque la instancia tenga PGA de sobra.
EXIT
