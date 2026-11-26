-- =====================================================================================================
-- herramientas/spm.sql · SQL Plan Management: líneas base de planes (runbook RB-4)
-- Uso: t6 spm lista [filtro|-]           líneas base cuyo texto contiene el filtro
--      t6 spm cargar SQL_ID              captura el plan ACTUAL del cursor como línea base aceptada
--      t6 spm evolucionar SQL_HANDLE     prueba los planes no aceptados frente al aceptado y acepta solo si es mejor
--      t6 spm quitar SQL_HANDLE          borra la línea base (vuelve a decidir el optimizador)
-- Regla: un plan solo cambia a MEJOR y con evidencia de ejecución real (lo verifica la tarea de evolución).
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN origin FORMAT A28
COLUMN texto FORMAT A34
COLUMN informe FORMAT A130
SET LONG 100000 LONGCHUNKSIZE 100000
VARIABLE tarea VARCHAR2(64)
DECLARE n PLS_INTEGER; e VARCHAR2(128);
BEGIN
  CASE LOWER('&1')
    WHEN 'cargar' THEN
      n := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(sql_id => '&2');
      DBMS_OUTPUT.PUT_LINE('Planes cargados como línea base aceptada: ' || n);
    WHEN 'evolucionar' THEN
      :tarea := DBMS_SPM.CREATE_EVOLVE_TASK(sql_handle => '&2');
      e := DBMS_SPM.EXECUTE_EVOLVE_TASK(:tarea);
    WHEN 'quitar' THEN
      n := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => '&2');
      DBMS_OUTPUT.PUT_LINE('Planes borrados: ' || n);
    ELSE NULL;
  END CASE;
END;
/
SET PAGESIZE 0
SELECT DBMS_SPM.REPORT_EVOLVE_TASK(:tarea, 'TEXT', 'TYPICAL', 'ALL') AS informe FROM dual WHERE :tarea IS NOT NULL;
SET PAGESIZE 200
PROMPT == Líneas base ==
SELECT sql_handle, plan_name, enabled, accepted, fixed, origin, SUBSTR(sql_text, 1, 34) AS texto
  FROM dba_sql_plan_baselines
 WHERE (LOWER('&1') = 'lista' AND ('&2' = '-' OR UPPER(sql_text) LIKE UPPER('%&2%')))
    OR (LOWER('&1') IN ('evolucionar', 'quitar') AND sql_handle = '&2')
    OR (LOWER('&1') = 'cargar' AND signature IN (SELECT exact_matching_signature FROM v$sql WHERE sql_id = '&2'))
 ORDER BY sql_handle, created;
EXIT
