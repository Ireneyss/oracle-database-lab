-- C22 · provocar · trabajo con memoria: el informe de fidelización (C19) tres veces con la PGA automática, y lecturas
-- variadas para que los asesores tengan datos del periodo. Efectos: ninguno en datos. Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
@@../C19_sql-monitor/_informe C22A
@@../C19_sql-monitor/_informe C22B
@@../C19_sql-monitor/_informe C22C
SET TERMOUT OFF
SELECT /* t6_c22 */ COUNT(*), SUM(importe) FROM t6.pedido WHERE codigo_postal LIKE '3%';
SELECT /* t6_c22 */ ciudad, COUNT(*) FROM t6.cliente GROUP BY ciudad ORDER BY 2 DESC FETCH FIRST 5 ROWS ONLY;
SET TERMOUT ON
PROMPT Hecho: carga con ordenaciones y agregados grandes. Siguiente fase: caso C22 entender
EXIT
