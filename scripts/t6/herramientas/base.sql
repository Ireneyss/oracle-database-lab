-- =====================================================================================================
-- herramientas/base.sql · la LÍNEA BASE de una sentencia: lo que hay que anotar ANTES de tocar nada (runbook RB-1)
-- Uso: t6 base registrar ETIQUETA SQL_ID [caso]     guarda las cifras por ejecución de V$SQLSTATS en T6.LINEA_BASE
--      t6 base ver [caso|-]                         la tabla de líneas base, con la mejora frente a la primera del caso
-- «Mejor» no es una impresión: es ms_ejec, gets_ejec y plan_hash de antes y de después, en la misma tabla.
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN etiqueta FORMAT A20
COLUMN caso FORMAT A4
COLUMN ms_ejec FORMAT 9999990.00
COLUMN mejora FORMAT A10
COLUMN hora FORMAT A8
BEGIN
  IF LOWER('&1') = 'registrar' THEN
    INSERT INTO t6.linea_base (caso, etiqueta, sql_id, plan_hash, ejecuciones, ms_ejec, cpu_ms_ejec, gets_ejec, lect_fis_ejec, filas_ejec)
    SELECT DECODE('&4', '-', NULL, '&4'), '&2', sql_id, plan_hash_value, executions,
           ROUND(elapsed_time / NULLIF(executions, 0) / 1000, 2), ROUND(cpu_time / NULLIF(executions, 0) / 1000, 2),
           ROUND(buffer_gets / NULLIF(executions, 0)), ROUND(disk_reads / NULLIF(executions, 0)),
           ROUND(rows_processed / NULLIF(executions, 0))
      FROM v$sqlstats WHERE sql_id = '&3' AND con_id = SYS_CONTEXT('USERENV', 'CON_ID');
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20610, 'El SQL_ID &3 no está en V$SQLSTATS: ejecútalo antes o búscalo con «t6 top»'); END IF;
    COMMIT;
  END IF;
END;
/
PROMPT == Líneas base registradas (T6.LINEA_BASE) ==
SELECT TO_CHAR(ts, 'HH24:MI:SS') AS hora, caso, etiqueta, sql_id, plan_hash, ejecuciones AS ejec, ms_ejec, gets_ejec, filas_ejec,
       CASE WHEN ms_ejec > 0 AND FIRST_VALUE(ms_ejec) OVER (PARTITION BY caso ORDER BY ts) > 0
            THEN 'x' || TO_CHAR(ROUND(FIRST_VALUE(ms_ejec) OVER (PARTITION BY caso ORDER BY ts) / ms_ejec, 1), 'FM9990.0') END AS mejora
  FROM t6.linea_base
 WHERE (LOWER('&1') = 'registrar' AND (caso = DECODE('&4', '-', caso, '&4') OR caso IS NULL))
    OR (LOWER('&1') = 'ver' AND ('&2' = '-' OR caso = '&2'))
 ORDER BY caso, ts;
EXIT
