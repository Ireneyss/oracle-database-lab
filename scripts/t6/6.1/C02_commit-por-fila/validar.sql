-- C02 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN l.ms_total < 0.5 * f.ms_total THEN 'OK    ' ELSE 'FALLO ' END
       || 'La carga por lotes tarda ' || l.ms_total || ' ms frente a ' || f.ms_total || ' ms por fila' AS resultado
  FROM t6.c02_medida f, t6.c02_medida l WHERE f.etq = 'POR_FILA' AND l.etq = 'POR_LOTE'
UNION ALL
SELECT CASE WHEN l.esperas_lfs < 0.05 * f.esperas_lfs THEN 'OK    ' ELSE 'FALLO ' END
       || 'Esperas «log file sync»: de ' || f.esperas_lfs || ' a ' || l.esperas_lfs
  FROM t6.c02_medida f, t6.c02_medida l WHERE f.etq = 'POR_FILA' AND l.etq = 'POR_LOTE'
UNION ALL
SELECT CASE WHEN COUNT(*) = 40000 THEN 'OK    ' ELSE 'FALLO ' END || 'Las dos cargas guardaron sus 20 000 filas (no se pierde nada)'
  FROM t6.venta_log;
EXIT
