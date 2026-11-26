-- C15 · entender · lo que ve el equipo de datos: la carga nocturna tarda varias veces más que hace dos años
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN etq FORMAT A14
SELECT etq, indices, ms, redo_mb, ROUND(ms / FIRST_VALUE(ms) OVER (ORDER BY indices), 1) AS veces_mas_lenta
  FROM t6.c15_medida ORDER BY indices;
PROMPT -- Lectura: el INSERT es el mismo; lo que cambia es que cada fila se escribe en la tabla y en seis árboles B.
PROMPT -- Cada índice añade lecturas de bloque, redo y undo. En la consulta ayudan; en la carga solo cuestan.
EXIT
