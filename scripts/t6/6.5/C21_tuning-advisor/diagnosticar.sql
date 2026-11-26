-- C21 · diagnosticar · SQL Tuning Advisor sobre el SQL_ID de la caché (alcance completo, 60 s como máximo)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
DECLARE t VARCHAR2(64); v VARCHAR2(13);
BEGIN
  SELECT sql_id INTO v FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1;
  t := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => v, scope => DBMS_SQLTUNE.SCOPE_COMPREHENSIVE, time_limit => 60,
                                       task_name => 'T6_C21_STA', description => 'INC-604: búsqueda por código postal V1');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK('T6_C21_STA');
END;
/
SET LONG 1000000 LONGCHUNKSIZE 1000000 LINESIZE 130 PAGESIZE 0
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('T6_C21_STA', 'TEXT', 'TYPICAL', 'FINDINGS') FROM dual;
EXIT
