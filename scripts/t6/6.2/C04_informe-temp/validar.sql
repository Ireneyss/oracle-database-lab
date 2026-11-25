-- C04 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Sin disparador heredado que fuerce WORKAREA_SIZE_POLICY = MANUAL' AS resultado
  FROM dba_triggers WHERE owner = 'T6' AND trigger_name = 'C04_LEGADO'
UNION ALL
SELECT CASE WHEN temp_escritos = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El informe de 100 filas no toca TEMP (' || temp_escritos || ' bloques)'
  FROM t6.c04_medida WHERE modo = 'AUTO_TOP100'
UNION ALL
SELECT CASE WHEN t.ms < 0.25 * l.ms THEN 'OK    ' ELSE 'FALLO ' END || 'Tiempo: ' || t.ms || ' ms frente a ' || l.ms || ' ms del informe heredado'
  FROM t6.c04_medida t, t6.c04_medida l WHERE t.modo = 'AUTO_TOP100' AND l.modo = 'LEGADO'
UNION ALL
SELECT CASE WHEN MIN(w.last_execution) = 'OPTIMAL' AND MAX(w.last_execution) = 'OPTIMAL' THEN 'OK    ' ELSE 'FALLO ' END
       || 'La ordenación del TOP 100 se resolvió en memoria (' || MAX(w.last_execution) || ')'
  FROM v$sql_workarea w JOIN v$sql s ON s.sql_id = w.sql_id AND s.child_number = w.child_number
 WHERE s.sql_text LIKE 'SELECT /*+ t6_informe_top100%';
EXIT
