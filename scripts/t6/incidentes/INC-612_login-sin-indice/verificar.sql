-- INC-612 · verificar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF SERVEROUTPUT OFF
COLUMN c NEW_VALUE correo
SELECT 'Cliente' || (1000 + &1 * 811) || '@TiendaSur.es' AS c FROM dual;
SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */ MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER('&correo');
SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */ MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER('&correo');
SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */ MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER('&correo');
SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */ MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER('&correo');
SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */ MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER('&correo');
SET TERMOUT ON
@@../_cabecera_verificar INC-612 &1 &2
SELECT CASE WHEN COUNT(*) >= 1 THEN 'OK    ' ELSE 'FALLO ' END || 'CLIENTE tiene un índice basado en función'
  FROM dba_indexes WHERE owner = 'T6' AND table_name = 'CLIENTE' AND index_type LIKE 'FUNCTION-BASED%' AND status = 'VALID'
UNION ALL
SELECT CASE WHEN COUNT(*) > 0 THEN 'OK    ' ELSE 'FALLO ' END || 'La búsqueda por correo va por índice (no recorre CLIENTE entera)'
  FROM v$sql_plan WHERE operation = 'INDEX'
   AND sql_id IN (SELECT sql_id FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */%')
UNION ALL
SELECT CASE WHEN MIN(buffer_gets / executions) < 500 THEN 'OK    ' ELSE 'FALLO ' END || 'Lecturas de la búsqueda por correo: '
       || ROUND(MIN(buffer_gets / executions)) FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS */ /* t6_inc612_verificar */%';
EXIT
