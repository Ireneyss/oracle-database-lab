-- C14 · entender · lo que ve el call center: cuántas filas devuelve el panel frente a cuántas lee
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN medida FORMAT A50
COLUMN valor FORMAT A20
SELECT 'Pedidos que muestra el panel' AS medida, TO_CHAR(COUNT(*)) AS valor FROM t6.pedido
 WHERE estado = 'P' AND canal = 'T' AND fecha_pedido >= DATE '2026-01-01'
UNION ALL
SELECT 'Pedidos que hay en la tabla', TO_CHAR(COUNT(*)) FROM t6.pedido
UNION ALL
SELECT 'Lecturas lógicas por apertura del panel', TO_CHAR(ROUND(buffer_gets / executions))
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel */%'
UNION ALL
SELECT 'Milisegundos por apertura', TO_CHAR(ROUND(elapsed_time / executions / 1000, 1))
  FROM v$sql WHERE sql_text LIKE 'SELECT /*+ t6_c14_panel */%';
PROMPT -- Lectura: el panel enseña unos 2 000 pedidos (el 0,2 %) y para ello lee la tabla entera. 30 aperturas por hora son
PROMPT -- 30 recorridos completos de un millón de filas. La petición del jefe del call center: «que vaya instantáneo».
EXIT
