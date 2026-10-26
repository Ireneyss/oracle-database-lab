-- scripts/lab5/08-reto-mttr.sql — reto de la Parte I: cómo crecen el redo pendiente y el MTTR estimado con una carga, sin checkpoint
-- Se ejecuta como SYSDBA. Reutiliza el paso 1 de 13-lgwr-dbwn.sql (UPDATE de 20 000 filas sin cambiar el valor).
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN momento FORMAT A34
PROMPT ===== Antes: checkpoint completo para partir de cero redo pendiente =====
ALTER SYSTEM CHECKPOINT;
SELECT 'tras ALTER SYSTEM CHECKPOINT' AS momento, estimated_mttr, actual_redo_blks, target_redo_blks, recovery_estimated_ios FROM v$instance_recovery;
PROMPT ===== Carga: UPDATE de 20 000 filas + COMMIT, sin checkpoint =====
ALTER SESSION SET CONTAINER = FREEPDB1;
UPDATE admin_academia.aca_estudiantes SET estado = estado;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;
SELECT 'tras UPDATE 20 000 + COMMIT' AS momento, estimated_mttr, actual_redo_blks, target_redo_blks, recovery_estimated_ios FROM v$instance_recovery;
PROMPT ===== Otra vez la misma carga =====
ALTER SESSION SET CONTAINER = FREEPDB1;
UPDATE admin_academia.aca_estudiantes SET estado = estado;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;
SELECT 'tras el segundo UPDATE + COMMIT' AS momento, estimated_mttr, actual_redo_blks, target_redo_blks, recovery_estimated_ios FROM v$instance_recovery;
SELECT name, value FROM v$parameter WHERE name IN ('fast_start_mttr_target', 'log_checkpoint_timeout');
EXIT
