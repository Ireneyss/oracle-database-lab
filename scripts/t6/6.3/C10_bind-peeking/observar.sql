-- C10 · observar · los hijos del cursor al final, la limpieza (sin histograma) y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN sensible FORMAT A8
COLUMN consciente FORMAT A10
SELECT child_number, plan_hash_value, executions, ROUND(buffer_gets / executions) AS gets_ejec, is_bind_sensitive AS sensible, is_bind_aware AS consciente
  FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c10 */%' ORDER BY child_number;
EXEC DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO', method_opt => 'FOR COLUMNS estado SIZE 1', no_invalidate => FALSE)
PROMPT == Lo que debes retener ==
PROMPT 1. Bind peeking: en el hard parse Oracle MIRA el valor de la variable y elige el plan para ese valor.
PROMPT 2. Con datos sesgados (histograma), el cursor es SENSIBLE; si el coste real cambia mucho, pasa a CONSCIENTE (ACS).
PROMPT 3. Las primeras ejecuciones con el valor «malo» pagan el plan equivocado: ACS aprende, no adivina.
PROMPT 4. Variante de examen: ¿por qué un informe va lento solo a veces? Mira los hijos en V$SQL y V$SQL_CS_STATISTICS.
EXIT
