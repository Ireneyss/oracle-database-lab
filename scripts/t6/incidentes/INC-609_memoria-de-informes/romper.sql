-- INC-609 · romper · un disparador de inicio de sesión «heredado» deja a T6_APP con memoria de trabajo MANUAL y diminuta
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN k NEW_VALUE kb
SELECT TO_CHAR(64 + MOD(&1, 7) * 16) AS k FROM dual;
CREATE OR REPLACE TRIGGER t6.trg_sesion_aplicacion AFTER LOGON ON t6_app.SCHEMA
BEGIN
  -- «optimización» de 2019 para que los informes no se coman la memoria
  EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = MANUAL';
  EXECUTE IMMEDIATE 'ALTER SESSION SET sort_area_size = ' || (&kb * 1024);
  EXECUTE IMMEDIATE 'ALTER SESSION SET hash_area_size = ' || (&kb * 2048);
END;
/
@@../_registro INC-609 &1 &2 "sort_area_size = &kb KB"
SET TERMOUT ON
PROMPT Roto: los informes de la aplicación (cuenta T6_APP) ya no son los de ayer.
EXIT
