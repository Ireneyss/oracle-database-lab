-- database/migrations/V006__ix_cli_telefono.sql
-- Reto de la Parte G (Lab 5): índice propio para Q5 (identificar a quien llama por email O teléfono), que V005 no cubre.
-- Las cinco preguntas, con cifras de docs/bitacora/lab5/evidencia/script/*_06-reto-v006.script.log:
--   1 Necesidad    Q5 hace TABLE ACCESS FULL CLIENTE: 1486 lecturas lógicas por llamada. Basta una rama del OR sin índice.
--   2 Viabilidad   telefono: 100 000 valores distintos, 0,001 % por valor: muy por debajo del punto de equilibrio (~0,5 %).
--                  Con el índice: BITMAP OR de UX_CLI_EMAIL e IX_CLI_TELEFONO, 6 lecturas (247 veces menos).
--   3 Escritura    INSERT en CLIENTE: 10,2 -> 12,1 bloques modificados por fila (+1,9) y 1445 -> 1640 bytes de redo.
--                  CLIENTE recibe altas, no 300 INSERT/s como PEDIDO: el coste es pequeño y acotado.
--   4 Redundancia  ningún índice de CLIENTE empieza por TELEFONO (0). Tamaño: 294 hojas, 3 MB.
--   5 Ciclo de vida se crea ONLINE; si DBA_INDEX_USAGE no lo muestra en uso tras un mes, INVISIBLE y después DROP.
-- Idempotente: si ya existe, no hace nada.
SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;
WHENEVER SQLERROR EXIT SUCCESS
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'IX_CLI_TELEFONO';
  IF n > 0 THEN RAISE_APPLICATION_ERROR(-20006, 'V006 ya aplicada: IX_CLI_TELEFONO existe, no se hace nada'); END IF;
END;
/
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE INDEX tiendasur.ix_cli_telefono ON tiendasur.cliente (telefono) ONLINE;
SELECT index_name, visibility, status FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'IX_CLI_TELEFONO';
EXIT
