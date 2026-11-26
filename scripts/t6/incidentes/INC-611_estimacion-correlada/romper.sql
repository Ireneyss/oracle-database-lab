-- INC-611 · romper · sin grupo de columnas (CIUDAD, COMUNIDAD): el optimizador multiplica dos selectividades que no son independientes
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
BEGIN
  FOR e IN (SELECT extension FROM dba_stat_extensions WHERE owner = 'T6' AND table_name = 'CLIENTE' AND creator = 'USER') LOOP
    DBMS_STATS.DROP_EXTENDED_STATS('T6', 'CLIENTE', e.extension); END LOOP;
  DBMS_STATS.GATHER_TABLE_STATS('T6', 'CLIENTE', method_opt => 'FOR ALL COLUMNS SIZE 1', no_invalidate => FALSE);
END;
/
COLUMN ciu NEW_VALUE ciudad
COLUMN com NEW_VALUE comunidad
SELECT 'Ciudad' || LPAD(100 + MOD(&1 * 53, 1800), 4, '0') AS ciu, 'COM' || LPAD(MOD(100 + MOD(&1 * 53, 1800), 17) + 1, 2, '0') AS com FROM dual;
@@../_registro INC-611 &1 &2 "listado de &ciudad / &comunidad"
SET TERMOUT ON
PROMPT Roto: el listado de clientes por ciudad y comunidad estima mal (mira tu ciudad en la primera línea de verificar).
EXIT
