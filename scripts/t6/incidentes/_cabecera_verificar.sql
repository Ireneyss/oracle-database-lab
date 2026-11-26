-- _cabecera_verificar.sql · primera línea de toda verificación: qué incidente, de quién y con qué detalle se rompió
SET ECHO OFF FEEDBACK OFF VERIFY OFF HEADING OFF PAGESIZE 0 LINESIZE 200
SELECT CASE WHEN COUNT(*) = 1 THEN 'OK    ' ELSE 'FALLO ' END || 'Incidente &1 roto para ' || MAX(alumno) || ' (semilla ' || MAX(semilla)
       || ') el ' || TO_CHAR(MAX(roto), 'YYYY-MM-DD HH24:MI') || ' · ' || MAX(detalle)
  FROM t6.inc_registro WHERE inc = '&1' AND alumno = '&3';
