-- C15 · observar · la tabla completa de medidas y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN etq FORMAT A14
SELECT etq, indices, ms, redo_mb FROM t6.c15_medida ORDER BY indices DESC, ms DESC;
PROMPT == Lo que debes retener ==
PROMPT 1. Cada índice acelera algunas lecturas y frena TODAS las escrituras de la tabla: se justifica con la consulta que sirve.
PROMPT 2. Un índice cuyo prefijo coincide con otro (ESTADO frente a ESTADO, FECHA_PEDIDO) suele sobrar: t6 indices TABLA.
PROMPT 3. Para cargas masivas: UNUSABLE + carga + REBUILD (o carga directa con /*+ APPEND */). Nunca con índices de PK o UNIQUE
PROMPT    que deban seguir validando duplicados durante la carga.
PROMPT 4. Antes de borrar uno que «nadie usa»: DBA_INDEX_USAGE e INVISIBLE una temporada (casos C14 y C23).
EXIT
