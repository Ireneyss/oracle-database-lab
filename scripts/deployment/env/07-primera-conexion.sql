-- scripts/deployment/env/07-primera-conexion.sql
SET ECHO ON
SET LINESIZE 150
ALTER SESSION SET CONTAINER = FREEPDB1;
SHOW CON_NAME;
SELECT instance_name, status, version FROM v$instance;
EXIT;
