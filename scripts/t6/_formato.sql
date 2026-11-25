-- =====================================================================================================
-- _formato.sql · formato común del kit del Tema 6 (lo carga cada script con @@../../_formato)
-- Objetivo: que en el proyector cada fila quepa en UNA línea y que se vea qué comando produce qué.
-- =====================================================================================================
SET ECHO OFF FEEDBACK OFF
SET TIME OFF TIMING OFF
SET SQLPROMPT "_USER'@'_CONNECT_IDENTIFIER> "
-- EXIT no confirma lo pendiente: en las demos, lo que no tiene COMMIT explícito se deshace al salir
-- (por defecto SQL*Plus hace COMMIT al salir; un script de producción tampoco debería fiarse de eso)
SET EXITCOMMIT OFF
SET LINESIZE 130 PAGESIZE 200 TRIMOUT ON TRIMSPOOL ON TAB OFF
SET VERIFY OFF HEADING ON SQLBLANKLINES ON
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WORD_WRAPPED
SET LONG 4000 LONGCHUNKSIZE 4000
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = 'YYYY-MM-DD HH24:MI:SS TZH:TZM';
-- Las columnas VARCHAR2 se muestran con su ancho declarado (a veces 128 o 4000 caracteres) y la fila
-- se parte en varias líneas. COLUMN ... FORMAT An fija el ancho. Estas son las que más salen en la unidad:
COLUMN username        FORMAT A18
COLUMN name            FORMAT A20
COLUMN con_name        FORMAT A10
COLUMN pdb             FORMAT A10
COLUMN tablespace_name FORMAT A18
COLUMN status          FORMAT A10
COLUMN open_mode       FORMAT A10
COLUMN restricted      FORMAT A4 HEADING RESTR
COLUMN profile         FORMAT A16
COLUMN account_status  FORMAT A16
COLUMN module          FORMAT A12
COLUMN action          FORMAT A15
COLUMN event           FORMAT A40
COLUMN wait_class      FORMAT A14
COLUMN service_name    FORMAT A13
COLUMN network_name    FORMAT A13
COLUMN member          FORMAT A50
COLUMN file_name       FORMAT A55
COLUMN value           FORMAT A50
COLUMN owner           FORMAT A15
COLUMN object_name     FORMAT A22
COLUMN object_type     FORMAT A12
COLUMN grantee         FORMAT A14
COLUMN grantor         FORMAT A14
COLUMN privilege       FORMAT A16
COLUMN table_name      FORMAT A18
COLUMN role            FORMAT A20
-- Cuenta de la aplicación del kit (T6_APP): solo para el contenedor del aula; 99_limpiar.sql la borra
DEFINE PWD_CASO = "Casos_T6#2026x"
-- Columnas propias de la Unidad 6 (rendimiento)
COLUMN sql_id          FORMAT A13
COLUMN stat_name       FORMAT A32
COLUMN metric_name     FORMAT A34
COLUMN column_name     FORMAT A16
COLUMN histogram       FORMAT A15
COLUMN extension_name  FORMAT A30
COLUMN extension       FORMAT A26
COLUMN index_name      FORMAT A20
COLUMN sql_text        FORMAT A90
COLUMN sql_handle      FORMAT A20
COLUMN plan_name       FORMAT A32
COLUMN operation_type  FORMAT A16
COLUMN policy          FORMAT A8
COLUMN client_name     FORMAT A32
COLUMN stale_stats     FORMAT A5 HEADING STALE
COLUMN preference_name FORMAT A22
COLUMN preference_value FORMAT A30
COLUMN metric_unit     FORMAT A28
COLUMN etq             FORMAT A10
COLUMN resultado       FORMAT A110
COLUMN plan_table_output FORMAT A150
SET FEEDBACK ON
SET ECHO ON
