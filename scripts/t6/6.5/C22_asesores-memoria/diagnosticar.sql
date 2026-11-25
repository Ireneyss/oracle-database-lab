-- C22 · diagnosticar · los asesores de SGA, PGA y caché de buffers (lo mismo que: t6 memoria)
@@../../_formato
SET ECHO OFF
PROMPT == Asesor de la SGA: DB time estimado para cada tamaño (factor 1 = el actual) ==
SELECT sga_size AS sga_mb, sga_size_factor AS factor_tamano, estd_db_time_factor AS factor_db_time, estd_physical_reads AS lecturas_fisicas_est
  FROM v$sga_target_advice ORDER BY sga_size;
PROMPT == Asesor de la PGA: aciertos de las áreas de trabajo y desbordes previstos ==
SELECT ROUND(pga_target_for_estimate / 1048576) AS pga_mb, pga_target_factor AS factor, estd_pga_cache_hit_percentage AS pct_aciertos,
       estd_overalloc_count AS desbordes_previstos
  FROM v$pga_target_advice ORDER BY pga_target_for_estimate;
COLUMN name FORMAT A34
SELECT name, ROUND(CASE WHEN unit = 'bytes' THEN value / 1048576 ELSE value END) AS valor, DECODE(unit, 'bytes', 'MB', unit) AS unidad
  FROM v$pgastat WHERE con_id = 0 AND name IN ('aggregate PGA target parameter', 'total PGA allocated', 'maximum PGA allocated',
                                               'cache hit percentage', 'over allocation count');
PROMPT -- Lectura: en la SGA, ¿cuánto baja FACTOR_DB_TIME si la SGA crece? En la PGA, ¿a partir de qué tamaño
PROMPT -- desaparecen los desbordes (DESBORDES_PREVISTOS = 0) y deja de subir el % de aciertos?
EXIT
