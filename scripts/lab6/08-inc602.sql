-- INC-602: el servicio academia_app existe pero está parado; el listener no lo anuncia (ORA-12514)
SET LINESIZE 120 FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;
EXEC DBMS_SERVICE.START_SERVICE('academia_app')
-- Guardar el estado de la PDB para que el servicio vuelva a arrancar tras un reinicio (Parte C)
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;
SELECT name FROM v$active_services WHERE name = 'academia_app';
EXIT
