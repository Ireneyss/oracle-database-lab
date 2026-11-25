-- =====================================================================================================
-- herramientas/plan.sql · el plan REAL de un cursor (lo que pasó, no lo que se predice) · playbook PB-2
-- Uso: t6 plan SQL_ID [child]       child por defecto: el último que se ejecutó
-- Muestra: (1) los hijos del cursor con su plan_hash_value y sus cifras por ejecución; (2) el plan con
--   E-Rows, A-Rows, Starts y Buffers (si la sentencia se ejecutó con GATHER_PLAN_STATISTICS o STATISTICS_LEVEL=ALL;
--   si no, solo E-Rows: es el aviso «Warning: basic plan statistics not available»), los predicados y los binds vistos.
-- Lectura: busca la PRIMERA línea (de dentro afuera) donde E-Rows × Starts se aleja de A-Rows en un orden de magnitud.
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 170
COLUMN plan_table_output FORMAT A165
COLUMN ms_ejec FORMAT 9999990.0
COLUMN bind_sens FORMAT A4 HEADING BSEN
COLUMN bind_aware FORMAT A4 HEADING BAWR
COLUMN plan_line FORMAT A100
PROMPT == 1 · Hijos del cursor &1 ==
SELECT child_number AS hijo, plan_hash_value AS plan_hash, executions AS ejec,
       ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 1) AS ms_ejec,
       ROUND(buffer_gets / NULLIF(executions, 0)) AS gets_ejec, is_bind_sensitive AS bind_sens, is_bind_aware AS bind_aware,
       sql_plan_baseline AS baseline
  FROM v$sql WHERE sql_id = '&1' ORDER BY child_number;
PROMPT == 2 · Plan real (ALLSTATS LAST) con predicados y variables de enlace observadas ==
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&1',
       CASE WHEN '&2' = '-' THEN NULL ELSE TO_NUMBER('&2') END, 'ALLSTATS LAST +COST +PREDICATE +PEEKED_BINDS -NOTE'));
PROMPT == 3 · Historia del plan en AWR (si la sentencia llegó a una instantánea) ==
SELECT snap_id, plan_hash_value AS plan_hash, executions_delta AS ejec,
       ROUND(elapsed_time_delta / NULLIF(executions_delta, 0) / 1000, 1) AS ms_ejec,
       ROUND(buffer_gets_delta / NULLIF(executions_delta, 0)) AS gets_ejec
  FROM dba_hist_sqlstat WHERE sql_id = '&1' ORDER BY snap_id DESC FETCH FIRST 6 ROWS ONLY;
PROMPT -- ¿Dos plan_hash distintos para el mismo SQL_ID? El plan ha cambiado: playbook PB-3.
EXIT
