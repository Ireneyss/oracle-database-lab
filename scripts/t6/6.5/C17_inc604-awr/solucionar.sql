-- C17 · solucionar · UN solo cambio: desplegar la V2 de la búsqueda (el parámetro pasa a VARCHAR2, igual que la columna)
-- Nada de índices nuevos, ni hints, ni estadísticas: si se cambian varias cosas a la vez, no se sabe cuál arregló qué.
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 160 SERVEROUTPUT OFF
COLUMN argumento FORMAT A20
COLUMN tipo FORMAT A10
COLUMN procedimiento FORMAT A22
SELECT subprogram_id, package_name || '.' || object_name AS procedimiento, argument_name AS argumento, data_type AS tipo
  FROM dba_arguments WHERE owner = 'T6' AND package_name = 'APP' AND object_name LIKE 'BUSCAR_CP%' ORDER BY 1;
PROMPT == Prueba de humo de la V2 antes de la carga: 20 búsquedas y su plan ==
SET ECHO OFF
BEGIN FOR i IN 1 .. 20 LOOP t6.app.buscar_cp_v2(TO_CHAR(30001 + MOD(i * 37, 5000))); END LOOP; ROLLBACK; END;
/
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_cp_v2 */%' AND ROWNUM = 1), NULL, 'BASIC +PREDICATE'));
PROMPT -- El despliegue: la web llama a buscar_cp_v2(TO_CHAR(:cp)). La fase validar repite LA MISMA carga con la V2.
EXIT
