-- C18 · observar · el plan nuevo no se pierde: queda NO aceptado y la evolución decide con números
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN plan_name FORMAT A32
COLUMN origin FORMAT A26
PROMPT == El optimizador quería el recorrido completo: lo guarda en la historia del plan, NO aceptado ==
SELECT plan_name, enabled, accepted, origin FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' ORDER BY created;
PROMPT == Evolución: Oracle ejecuta los dos planes, los compara y acepta el nuevo SOLO si es mejor ==
VARIABLE tarea VARCHAR2(64)
DECLARE h VARCHAR2(128); e VARCHAR2(128);
BEGIN
  SELECT sql_handle INTO h FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' AND ROWNUM = 1;
  :tarea := DBMS_SPM.CREATE_EVOLVE_TASK(sql_handle => h);
  e := DBMS_SPM.EXECUTE_EVOLVE_TASK(:tarea);
END;
/
SET LONG 100000 LONGCHUNKSIZE 100000 PAGESIZE 0 LINESIZE 130
SELECT DBMS_SPM.REPORT_EVOLVE_TASK(:tarea, 'TEXT', 'TYPICAL', 'FINDINGS') FROM dual;
SET PAGESIZE 100
SELECT plan_name, enabled, accepted, origin FROM dba_sql_plan_baselines WHERE sql_text LIKE 'SELECT /* t6_c18_pendientes */%' ORDER BY created;
PROMPT == Lo que debes retener ==
PROMPT 1. SPM no adivina el mejor plan: protege el plan PROBADO. Un plan nuevo entra como no aceptado y espera su evolución.
PROMPT 2. Fuentes de planes: caché de cursores (t6 spm cargar SQL_ID), AWR (LOAD_PLANS_FROM_AWR) o un SQL Tuning Set.
PROMPT 3. La sentencia la debe analizar la cuenta de la aplicación: con SYS la evolución falla (ORA-16963).
PROMPT 4. La causa sigue ahí (las preferencias SIZE 1): SPM da tiempo, pero el DBA arregla también las estadísticas (C13, RB-2).
PROMPT 5. Variante de examen: «el plan cambió tras un parche»: DBA_HIST_SQLSTAT por PLAN_HASH_VALUE y SPM (playbook PB-3).
EXIT
