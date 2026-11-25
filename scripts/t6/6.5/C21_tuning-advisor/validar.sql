-- C21 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'La tarea T6_C21_STA terminó (COMPLETED)' AS resultado
  FROM dba_advisor_tasks WHERE task_name = 'T6_C21_STA' AND status = 'COMPLETED'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El asesor ha dejado hallazgos (' || COUNT(*) || ')'
  FROM dba_advisor_findings WHERE task_name = 'T6_C21_STA'
UNION ALL
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'No se ha aceptado ningún perfil SQL a ciegas para la búsqueda V1'
  FROM dba_sql_profiles WHERE sql_text LIKE '%t6_cp_v1%';
EXIT
