-- scripts/lab4/03-reto-omf.sql — reto C: destino por defecto (OMF) dentro del volumen
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET LINESIZE 160 PAGESIZE 50 FEEDBACK ON
COLUMN name FORMAT A22
COLUMN value FORMAT A40
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' SCOPE = BOTH;
SELECT name, value FROM v$parameter WHERE name = 'db_create_file_dest';
-- Prueba: un tablespace SIN cláusula DATAFILE (nombre que no empieza por TBS_)
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE TABLESPACE prueba_omf;
COLUMN file_name FORMAT A90
SELECT tablespace_name, file_name FROM dba_data_files WHERE tablespace_name = 'PRUEBA_OMF';
DROP TABLESPACE prueba_omf INCLUDING CONTENTS AND DATAFILES;
EXIT
