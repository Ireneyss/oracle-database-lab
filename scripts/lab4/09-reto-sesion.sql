-- scripts/lab4/09-reto-sesion.sql — reto H: la sesión de usuario que más PGA usa ahora mismo
SET LINESIZE 180 PAGESIZE 50 FEEDBACK OFF
COLUMN username FORMAT A12
COLUMN sql_text FORMAT A60 TRUNCATED
SELECT s.sid, s.serial#, s.username, s.con_id, s.status, p.spid,
       ROUND(p.pga_used_mem / 1048576, 1) AS pga_usada_mb,
       ROUND(p.pga_alloc_mem / 1048576, 1) AS pga_asignada_mb,
       q.sql_text
  FROM v$session s
  JOIN v$process p ON p.addr = s.paddr
  LEFT JOIN v$sql q ON q.sql_id = s.sql_id AND q.child_number = s.sql_child_number AND q.con_id = s.con_id
 WHERE s.type = 'USER' AND s.status = 'ACTIVE'
 ORDER BY p.pga_used_mem DESC;
EXIT
