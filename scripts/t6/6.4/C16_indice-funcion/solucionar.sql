-- C16 · solucionar · índice basado en función sobre UPPER(email) y estadísticas de su columna oculta
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF LINESIZE 170
CREATE INDEX t6.ix_t6_cli_email_up ON t6.cliente (UPPER(email)) TABLESPACE tbs_t6;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'CLIENTE', method_opt => 'FOR ALL HIDDEN COLUMNS SIZE 1', no_invalidate => FALSE)
SET ECHO OFF
DECLARE v NUMBER;
BEGIN
  FOR i IN 1 .. 50 LOOP
    SELECT /*+ t6_c16_login_v2 */ MAX(id_cliente) INTO v FROM t6.cliente
     WHERE UPPER(email) = UPPER('Cliente' || (i * 997) || '@TiendaSur.es');
  END LOOP;
END;
/
SET ECHO ON
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(
  (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login_v2 */%' AND ROWNUM = 1), NULL, 'BASIC +PREDICATE'));
SELECT 'Búsquedas con el índice: ' || ROUND(elapsed_time / executions / 1000, 2) || ' ms y '
       || ROUND(buffer_gets / executions) || ' lecturas lógicas cada una' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login_v2 */%';
EXIT
