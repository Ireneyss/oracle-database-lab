-- INC-601: terminar la sesión que bloquea la fila del alumno 101 (bloqueador SID 19, SERIAL# 38818)
SET LINESIZE 120 FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SYSTEM KILL SESSION '19,38818' IMMEDIATE;
-- Dar unos segundos a la sesión de Ana para que complete su UPDATE y su COMMIT
EXEC DBMS_SESSION.SLEEP(3)
SELECT estudiante_id, estado FROM admin_academia.aca_estudiantes WHERE estudiante_id = 101;
EXIT
