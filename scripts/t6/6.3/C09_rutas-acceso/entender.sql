-- C09 · entender · las siete preguntas: antes de mirar el plan, escribe qué ruta crees que elegirá Oracle y por qué
@@../../_formato
SET ECHO OFF
PROMPT 1. SELECT * FROM t6.pedido WHERE importe * 2 > 900                         (expresión sobre la columna)
PROMPT 2. SELECT * FROM t6.pedido WHERE id_pedido = 4711                          (igualdad en la clave primaria)
PROMPT 3. SELECT * FROM t6.pedido WHERE fecha_pedido >= SYSDATE - 1                (rango estrecho, índice no único)
PROMPT 4. SELECT id_pedido, importe FROM t6.pedido ORDER BY id_pedido DESC FETCH FIRST 10 ROWS ONLY
PROMPT 5. SELECT COUNT(*) FROM t6.pedido                                           (columna NOT NULL indexada)
PROMPT 6. SELECT canal, importe FROM t6.pedido WHERE importe = 123.45              (segunda columna de un índice)
PROMPT 7. SELECT * FROM t6.pedido WHERE id_cliente > 20000                         (el 80 % de las filas)
EXIT
