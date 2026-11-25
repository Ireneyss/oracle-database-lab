-- =====================================================================================================
-- herramientas/memoria.sql · ¿la memoria es el cuello de botella? Asesores de SGA y PGA y áreas de trabajo
-- Uso: t6 memoria          Solo lectura. Lo que se lee: factor 1 = tamaño actual; ¿cuánto bajaría el DB time o las
--   lecturas con más memoria? Si casi nada, la memoria no es el problema (no la amplíes «por si acaso»).
-- =====================================================================================================
@@../_formato
SET ECHO OFF FEEDBACK OFF
COLUMN sga_size_factor FORMAT 90.00 HEADING FACTOR
COLUMN pga_target_factor FORMAT 90.00 HEADING FACTOR
COLUMN estd_pga_cache_hit_percentage FORMAT 990 HEADING "ACIERTO %"
PROMPT == 1 · Tamaños actuales ==
SELECT name, ROUND(value / 1024 / 1024) AS mb FROM v$parameter
 WHERE name IN ('sga_target', 'pga_aggregate_target', 'memory_target', 'sga_max_size') ORDER BY name;
SELECT ROUND(SUM(value) / 1024 / 1024) AS pga_asignada_mb FROM v$pgastat WHERE name = 'total PGA allocated';
PROMPT == 2 · Asesor de la SGA: DB time estimado con otros tamaños ==
SELECT sga_size AS sga_mb, sga_size_factor, estd_db_time, estd_physical_reads FROM v$sga_target_advice ORDER BY sga_size;
PROMPT == 3 · Asesor de la PGA: acierto de caché y pasadas extra a TEMP con otros tamaños ==
SELECT ROUND(pga_target_for_estimate / 1024 / 1024) AS pga_mb, pga_target_factor, estd_pga_cache_hit_percentage,
       estd_overalloc_count AS sobreasignaciones
  FROM v$pga_target_advice ORDER BY pga_target_for_estimate;
PROMPT == 4 · Áreas de trabajo desde el arranque: en memoria (optimal), una pasada y varias ==
SELECT name, value FROM v$sysstat WHERE name LIKE 'workarea executions%';
EXIT
