-- scripts/lab5/15-reto-alerta.sql — reto de la Parte P: una comprobación que devuelve UNA fila solo cuando hay que despertar a alguien
-- SQLcl · C##OPS_RO · servicio FREE. Solo lectura. Uso: bash scripts/ops/ro.sh scripts/lab5/15-reto-alerta.sql
-- Pensada para un sistema de alertas: 0 filas = todo bien; 1 o más filas = abrir incidencia con el texto de la fila.
@scripts/ops/marca
SPOOL docs/bitacora/lab5/evidencia/spool/&marca._15-reto-alerta.spool.log
SET SQLFORMAT DEFAULT
SET LINESIZE 160 PAGESIZE 50 FEEDBACK ON VERIFY OFF
COLUMN alerta FORMAT A40
COLUMN detalle FORMAT A70
PROMPT == Umbral real de guardia: FRA > 85 % o ninguna copia RMAN completada en 24 h (vacío = no despertar a nadie) ==
DEFINE umbral = 85
SELECT 'FRA por encima del ' || &umbral || ' %' AS alerta,
       ROUND(100 * (space_used - space_reclaimable) / space_limit, 1) || ' % usado de ' || ROUND(space_limit / 1048576) || ' MB' AS detalle
  FROM v$recovery_file_dest
 WHERE space_limit > 0 AND (space_used - space_reclaimable) > space_limit * &umbral / 100
UNION ALL
SELECT 'Sin copia RMAN en 24 h', 'Última copia completada: ' || NVL(TO_CHAR(MAX(end_time), 'YYYY-MM-DD HH24:MI'), 'nunca')
  FROM v$rman_backup_job_details WHERE status LIKE 'COMPLETED%'
HAVING MAX(end_time) IS NULL OR MAX(end_time) < SYSDATE - 1;
PROMPT == Prueba de que dispara: el mismo SQL con un umbral del 1 % (la FRA está por encima) ==
DEFINE umbral = 1
SELECT 'FRA por encima del ' || &umbral || ' %' AS alerta,
       ROUND(100 * (space_used - space_reclaimable) / space_limit, 1) || ' % usado de ' || ROUND(space_limit / 1048576) || ' MB' AS detalle
  FROM v$recovery_file_dest
 WHERE space_limit > 0 AND (space_used - space_reclaimable) > space_limit * &umbral / 100;
SPOOL OFF
