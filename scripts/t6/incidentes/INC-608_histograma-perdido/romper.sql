-- INC-608 · romper · las preferencias de PEDIDO piden SIZE 1 y la recogida nocturna borra el histograma de ESTADO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN v NEW_VALUE valor
SELECT CASE MOD(&1, 3) WHEN 0 THEN 'P' WHEN 1 THEN 'D' ELSE 'P' END AS v FROM dual;
EXEC DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO', 'METHOD_OPT', 'FOR ALL COLUMNS SIZE 1')
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', no_invalidate => FALSE)
@@../_registro INC-608 &1 &2 "informe por estado = &valor"
SET TERMOUT ON
PROMPT Roto: el informe de pedidos por estado de la mañana ya no es el de ayer.
EXIT
