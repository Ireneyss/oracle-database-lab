-- INC-612 · romper · alguien «limpió índices sin uso» y se llevó el índice basado en función de UPPER(email)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
BEGIN FOR i IN (SELECT DISTINCT e.index_name FROM dba_ind_expressions e WHERE e.index_owner = 'T6' AND e.table_name = 'CLIENTE') LOOP
  EXECUTE IMMEDIATE 'DROP INDEX t6.' || i.index_name; END LOOP; END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
COLUMN c NEW_VALUE correo
SELECT 'Cliente' || (1000 + &1 * 811) || '@TiendaSur.es' AS c FROM dual;
@@../_registro INC-612 &1 &2 "correo de prueba &correo"
SET TERMOUT ON
PROMPT Roto: «¿Olvidaste tu contraseña?» ya no responde como ayer.
EXIT
