-- C20 · solucionar · comprobar que no queda ninguna traza activa y localizar el archivo para adjuntarlo al ticket
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN primary_id FORMAT A14
COLUMN qualifier_id1 FORMAT A14
SELECT trace_type, primary_id, qualifier_id1, qualifier_id2 FROM dba_enabled_traces;
COLUMN value FORMAT A60
ALTER SESSION SET CONTAINER = CDB$ROOT;
SELECT value FROM v$diag_info WHERE name = 'Diag Trace';
PROMPT -- El diagnóstico apunta a dos cambios en la aplicación, que se piden a desarrollo con el tkprof como evidencia:
PROMPT -- 1) fichas con variables de enlace (ficha_bind, caso C03); 2) el panel de ventas fuera del flujo del alta (caso C01).
PROMPT -- El DBA no cambia el código: aporta la medida y vuelve a trazar después para demostrar la mejora.
EXIT
