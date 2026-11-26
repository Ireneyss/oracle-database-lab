-- =====================================================================================================
-- herramientas/awr.sql · Automatic Workload Repository de la PDB (runbook RB-1)       Licencia: Diagnostics Pack
-- Uso: t6 awr snap                       crea una instantánea ahora (antes y después de una prueba)
--      t6 awr lista                      las últimas instantáneas de la PDB
--      t6 awr top INI FIN                las sentencias con más tiempo entre dos instantáneas (DELTAS, no acumulados)
--      t6 awr addm INI FIN               diagnóstico ADDM del intervalo: hallazgos cuantificados y recomendaciones
--      t6 awr informe INI FIN            el informe AWR completo en texto (se guarda en salidas/awr_INI_FIN.txt)
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
COLUMN texto FORMAT A40
COLUMN inicio FORMAT A16
COLUMN fin FORMAT A16
VARIABLE s NUMBER
VARIABLE tarea VARCHAR2(60)
BEGIN
  IF LOWER('&1') = 'snap' THEN :s := DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT; DBMS_OUTPUT.PUT_LINE('instantanea=' || :s); END IF;
  IF LOWER('&1') = 'addm' THEN
    :tarea := 'T6_ADDM_&2._&3';
    BEGIN DBMS_ADDM.DELETE(:tarea); EXCEPTION WHEN OTHERS THEN NULL; END;
    DBMS_ADDM.ANALYZE_DB(:tarea, &2, &3);
  END IF;
END;
/
SELECT snap_id, TO_CHAR(begin_interval_time, 'YYYY-MM-DD HH24:MI') AS inicio, TO_CHAR(end_interval_time, 'YYYY-MM-DD HH24:MI') AS fin
  FROM awr_pdb_snapshot WHERE LOWER('&1') IN ('lista', 'snap') ORDER BY snap_id DESC FETCH FIRST 6 ROWS ONLY;
SELECT s.sql_id, s.plan_hash_value AS plan_hash, SUM(s.executions_delta) AS ejec, ROUND(SUM(s.elapsed_time_delta) / 1e6, 1) AS seg,
       ROUND(SUM(s.elapsed_time_delta) / NULLIF(SUM(s.executions_delta), 0) / 1000, 2) AS ms_ejec,
       ROUND(SUM(s.buffer_gets_delta) / NULLIF(SUM(s.executions_delta), 0)) AS gets_ejec,
       (SELECT SUBSTR(REGEXP_REPLACE(DBMS_LOB.SUBSTR(t.sql_text, 200, 1), '\s+', ' '), 1, 40) FROM awr_pdb_sqltext t
         WHERE t.sql_id = s.sql_id AND ROWNUM = 1) AS texto
  FROM awr_pdb_sqlstat s
 WHERE LOWER('&1') = 'top' AND s.snap_id > &2 AND s.snap_id <= &3
 GROUP BY s.sql_id, s.plan_hash_value ORDER BY seg DESC FETCH FIRST 6 ROWS ONLY;
SET LONG 1000000 LONGCHUNKSIZE 1000000 PAGESIZE 0 LINESIZE 130
SELECT DBMS_ADDM.GET_REPORT(:tarea) FROM dual WHERE LOWER('&1') = 'addm';
EXIT
