-- C05 · provocar · el informe «importe por cliente de España» con una sugerencia copiada de otro informe (el de Lorca)
-- Alguien pegó /*+ USE_NL INDEX */ porque «en el informe de Lorca iba de maravilla». Efectos: ninguno (solo lectura).
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT OFF TIMING ON
SET TERMOUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c p) USE_NL(p) INDEX(p ix_t6_ped_cliente) t6_c05_nl */ c.id_cliente, SUM(p.importe) AS total
  FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.pais = 'ES' GROUP BY c.id_cliente;
SET TERMOUT ON TIMING OFF
SELECT sql_id, executions, ROUND(elapsed_time / 1000) AS ms, buffer_gets AS gets, rows_processed AS filas
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c p) USE_NL%t6_c05_nl%';
EXIT
