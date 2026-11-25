-- C22 · entender · la pregunta del jefe: «¿le ponemos más memoria a la base?» Primero, cómo está repartida ahora
-- La memoria es de la INSTANCIA (CDB), no de una PDB: este paso se ejecuta en la raíz.
@@../../_formato
SET ECHO OFF
COLUMN name FORMAT A22
COLUMN component FORMAT A28
SELECT name, ROUND(value / 1048576) AS mb FROM v$parameter
 WHERE name IN ('sga_target', 'sga_max_size', 'pga_aggregate_target', 'pga_aggregate_limit', 'memory_target') ORDER BY name;
SELECT component, ROUND(current_size / 1048576) AS mb FROM v$sga_dynamic_components WHERE current_size > 0 ORDER BY current_size DESC;
PROMPT -- Lectura: Oracle Free limita la SGA a 2 GB. Antes de pedir memoria hay que demostrar que serviría: los asesores.
EXIT
