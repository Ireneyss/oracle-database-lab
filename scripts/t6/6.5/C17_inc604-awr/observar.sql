-- C17 · observar · la evidencia para cerrar el INC-604: antes y después en AWR, con el plan guardado en el repositorio
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF LINESIZE 160
COLUMN version FORMAT A7
COLUMN intervalo FORMAT A12
SELECT CASE WHEN q.snap_id <= s.a2 THEN 'V1' ELSE 'V2' END AS version, q.sql_id, q.plan_hash_value,
       SUM(q.executions_delta) AS ejecuciones,
       ROUND(SUM(q.elapsed_time_delta) / NULLIF(SUM(q.executions_delta), 0) / 1000, 2) AS ms_por_ejec,
       ROUND(SUM(q.buffer_gets_delta) / NULLIF(SUM(q.executions_delta), 0)) AS gets_por_ejec
  FROM awr_pdb_sqlstat q,
       (SELECT MAX(DECODE(etq, 'V1_INI', snap_id)) a1, MAX(DECODE(etq, 'V1_FIN', snap_id)) a2,
               MAX(DECODE(etq, 'V2_INI', snap_id)) b1, MAX(DECODE(etq, 'V2_FIN', snap_id)) b2 FROM t6.c17_snap) s
 WHERE ((q.snap_id > s.a1 AND q.snap_id <= s.a2) OR (q.snap_id > s.b1 AND q.snap_id <= s.b2))
   AND q.sql_id IN (SELECT sql_id FROM awr_pdb_sqltext WHERE DBMS_LOB.SUBSTR(sql_text, 30, 1) LIKE 'SELECT /*+ t6_cp_v%')
 GROUP BY CASE WHEN q.snap_id <= s.a2 THEN 'V1' ELSE 'V2' END, q.sql_id, q.plan_hash_value ORDER BY 1;
PROMPT == El plan de la V1, guardado en AWR (sirve aunque el cursor ya no esté en memoria) ==
PROMPT -- En una PDB: awr_location => 'AWR_PDB'. Sin él se lee el AWR de la raíz y no sale nada.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(
  sql_id => (SELECT sql_id FROM awr_pdb_sqltext WHERE DBMS_LOB.SUBSTR(sql_text, 30, 1) LIKE 'SELECT /*+ t6_cp_v1 */%' AND ROWNUM = 1),
  format => 'BASIC +ROWS +COST', awr_location => 'AWR_PDB'));
PROMPT == Lo que debes retener (método de los 8 pasos, playbook PB-2) ==
PROMPT 1. Definir: el síntoma en SLI y SLO (p95 < 20 ms), no en adjetivos. Línea base ANTES de tocar nada (t6 base, t6 awr snap).
PROMPT 2. De lo general a lo concreto: ASH dice quién y en qué; AWR, qué SQL del intervalo; ADDM lo cuantifica; el plan, por qué.
PROMPT 3. UN solo cambio y la MISMA carga para medir: así la mejora tiene una causa demostrable.
PROMPT 4. La evidencia del cierre: AWR antes y después del mismo SQL (deltas), no una impresión.
PROMPT 5. Variante de examen: ADDM propone «SQL Tuning Advisor» o un índice; la causa real era el tipo de dato (caso C21).
EXIT
