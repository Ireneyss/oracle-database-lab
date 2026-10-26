-- scripts/lab5/10-reto-dimensionar-redo.sql — reto de la Parte K: cambios de log por hora y redo generado, para dimensionar los grupos
-- Se ejecuta como SYSDBA. Solo lectura.
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN hora FORMAT A16
PROMPT ===== 1. Cambios de log por hora (hoy) =====
SELECT TO_CHAR(first_time, 'YYYY-MM-DD HH24') AS hora, COUNT(*) AS cambios_de_log
  FROM v$log_history WHERE first_time > TRUNC(SYSDATE) GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24') ORDER BY 1;
PROMPT ===== 2. Redo archivado por hora (MB) =====
SELECT TO_CHAR(first_time, 'YYYY-MM-DD HH24') AS hora, COUNT(*) AS archivados, ROUND(SUM(blocks * block_size) / 1048576) AS mb_redo
  FROM v$archived_log WHERE first_time > TRUNC(SYSDATE) AND dest_id = 1 GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24') ORDER BY 1;
PROMPT ===== 3. Detalle de los archivados de hoy =====
SELECT sequence#, TO_CHAR(first_time, 'HH24:MI:SS') AS inicio, TO_CHAR(next_time, 'HH24:MI:SS') AS fin,
       ROUND(blocks * block_size / 1048576) AS mb
  FROM v$archived_log WHERE first_time > TRUNC(SYSDATE) AND dest_id = 1 ORDER BY sequence#;
PROMPT ===== 4. Tamaño actual de los grupos =====
SELECT group#, members, ROUND(bytes / 1048576) AS mb, status FROM v$log ORDER BY group#;
EXIT
