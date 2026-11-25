-- 99_limpiar.sql · Tema 6 / Laboratorio 7 · borra todo lo que crea el kit (banco T6, T6_APP, líneas base de SPM,
-- tareas de asesores y parámetros cambiados en la PDB). Ejecutar al terminar el tema: caso --limpiar
@@_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
DECLARE n NUMBER;
BEGIN
  FOR b IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE sql_text LIKE '%t6%' OR sql_text LIKE '%T6.%') LOOP
    n := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => b.sql_handle);
  END LOOP;
  FOR p IN (SELECT name FROM dba_sql_profiles WHERE name LIKE 'T6%' OR sql_text LIKE '%t6.%') LOOP DBMS_SQLTUNE.DROP_SQL_PROFILE(p.name); END LOOP;
  FOR t IN (SELECT task_name FROM dba_advisor_tasks WHERE task_name LIKE 'T6%') LOOP
    BEGIN DBMS_SQLTUNE.DROP_TUNING_TASK(t.task_name); EXCEPTION WHEN OTHERS THEN DBMS_ADVISOR.DELETE_TASK(t.task_name); END;
  END LOOP;
  FOR p IN (SELECT name FROM v$system_parameter WHERE isdefault = 'FALSE' AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
               AND name IN ('optimizer_mode', 'optimizer_index_cost_adj', 'optimizer_features_enable', 'cursor_sharing',
                            'optimizer_use_invisible_indexes', 'optimizer_use_pending_statistics', 'pga_aggregate_target',
                            'optimizer_capture_sql_plan_baselines', 'optimizer_adaptive_plans', 'db_file_multiblock_read_count',
                            'statistics_level', 'optimizer_dynamic_sampling')) LOOP
    EXECUTE IMMEDIATE 'ALTER SYSTEM RESET ' || p.name || ' SCOPE = BOTH';
  END LOOP;
  FOR u IN (SELECT username FROM dba_users WHERE username IN ('T6', 'T6_APP')) LOOP EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE'; END LOOP;
  SELECT COUNT(*) INTO n FROM dba_tablespaces WHERE tablespace_name = 'TBS_T6';
  IF n > 0 THEN EXECUTE IMMEDIATE 'DROP TABLESPACE tbs_t6 INCLUDING CONTENTS AND DATAFILES'; END IF;
END;
/
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Kit del Tema 6 retirado (T6, T6_APP, TBS_T6)' AS resultado
  FROM dba_users WHERE username IN ('T6', 'T6_APP');
EXIT
