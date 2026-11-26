-- C20 · observar · lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
PROMPT == Lo que debes retener ==
PROMPT 1. Se traza lo justo: DBMS_MONITOR por servicio, módulo y acción (o por sesión) y se desactiva al acabar.
PROMPT 2. tkprof sort=exeela,fchela pone arriba lo que más tarda; sys=no quita el SQL recursivo de Oracle.
PROMPT 3. Por sentencia: count, cpu, elapsed, disk, query (lecturas lógicas) y rows en Parse, Execute y Fetch.
PROMPT 4. Parse casi igual a Execute y «Misses in library cache» = análisis completos: falta usar variables (C03).
PROMPT 5. Una traza por sesión: para juntar varias del mismo módulo, trcsess module=tienda_web y luego tkprof.
EXIT
