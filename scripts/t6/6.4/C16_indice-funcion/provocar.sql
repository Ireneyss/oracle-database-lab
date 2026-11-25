-- C16 · provocar · el formulario «¿Olvidaste tu contraseña?» busca el cliente por email sin distinguir mayúsculas
-- La web hace WHERE UPPER(email) = UPPER(:correo). Existe un índice sobre EMAIL... pero no sobre UPPER(EMAIL).
-- Efectos: ninguno en datos. Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT OFF
BEGIN FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_CLI_EMAIL_UP') LOOP
  EXECUTE IMMEDIATE 'DROP INDEX t6.ix_t6_cli_email_up'; END LOOP; END;
/
PROMPT == 50 clientes piden recuperar la contraseña (escriben el correo como les sale) ==
DECLARE v NUMBER;
BEGIN
  FOR i IN 1 .. 50 LOOP
    SELECT /*+ t6_c16_login */ MAX(id_cliente) INTO v FROM t6.cliente
     WHERE UPPER(email) = UPPER('Cliente' || (i * 997) || '@TiendaSur.es');
  END LOOP;
END;
/
SELECT 'Búsquedas: ' || executions || ' · ' || ROUND(elapsed_time / executions / 1000, 2) || ' ms y '
       || ROUND(buffer_gets / executions) || ' lecturas lógicas cada una' AS resultado
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c16_login */%';
EXIT
