-- INC-603: APP_ACADEMIA bloqueada a mano (LOCKED, no TIMED) por el script de bajas; se desbloquea sin cambiar la contraseña
SET LINESIZE 120 FEEDBACK ON
COLUMN username FORMAT A13
COLUMN account_status FORMAT A16
COLUMN profile FORMAT A13
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER USER app_academia ACCOUNT UNLOCK;
SELECT username, account_status, profile FROM dba_users WHERE username = 'APP_ACADEMIA';
EXIT
