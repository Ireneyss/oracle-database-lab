-- C15 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'El índice redundante IX_C15_5 ya no existe' AS resultado
  FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_C15_5'
UNION ALL
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK    ' ELSE 'FALLO ' END || 'Ningún índice de C15_CARGA queda UNUSABLE tras la carga'
  FROM dba_indexes WHERE owner = 'T6' AND table_name = 'C15_CARGA' AND status = 'UNUSABLE'
UNION ALL
SELECT CASE WHEN s.ms > 2 * c.ms THEN 'OK    ' ELSE 'FALLO ' END || 'Con seis índices la carga cuesta más del doble que sin ninguno: '
       || c.ms || ' ms frente a ' || s.ms || ' ms'
  FROM (SELECT ms FROM t6.c15_medida WHERE etq = 'SIN_INDICES') c, (SELECT ms FROM t6.c15_medida WHERE etq = 'SEIS_INDICES') s;
EXIT
