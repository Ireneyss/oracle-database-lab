-- C22 · solucionar · la decisión con números: el tamaño mínimo que da (casi) todo el beneficio, no el máximo posible
@@../../_formato
SET ECHO OFF
COLUMN conclusion FORMAT A120
WITH s AS (SELECT sga_size, sga_size_factor, estd_db_time_factor f FROM v$sga_target_advice),
     a AS (SELECT MIN(f) fmin, MAX(sga_size) smax FROM s), c AS (SELECT sga_size, f FROM s WHERE sga_size_factor = 1)
SELECT 'SGA: actual ' || c.sga_size || ' MB. Con la mayor estimada (' || a.smax || ' MB) el DB time baja un '
       || ROUND((c.f - a.fmin) / c.f * 100, 1) || ' %. Con menos de un 5 % no compensa ampliarla.' AS conclusion
  FROM a, c
UNION ALL
SELECT 'PGA: el menor tamaño sin desbordes previstos es ' || m.mb || ' MB (actual ' || p.mb || ' MB).'
  FROM (SELECT ROUND(MIN(pga_target_for_estimate) / 1048576) mb FROM v$pga_target_advice WHERE estd_overalloc_count = 0) m,
       (SELECT ROUND(value / 1048576) mb FROM v$parameter WHERE name = 'pga_aggregate_target') p;
PROMPT -- La decisión se toma con semanas de AWR (DBA_HIST_SGA_TARGET_ADVICE, DBA_HIST_PGASTAT), no con una foto:
COLUMN fin FORMAT A16
SELECT s.snap_id, TO_CHAR(s.end_interval_time, 'YYYY-MM-DD HH24:MI') AS fin,
       ROUND(MAX(CASE WHEN p.name = 'maximum PGA allocated' THEN p.value END) / 1048576) AS pga_maxima_mb
  FROM dba_hist_snapshot s JOIN dba_hist_pgastat p ON p.snap_id = s.snap_id AND p.dbid = s.dbid AND p.instance_number = s.instance_number
 GROUP BY s.snap_id, s.end_interval_time ORDER BY s.snap_id DESC FETCH FIRST 4 ROWS ONLY;
EXIT
