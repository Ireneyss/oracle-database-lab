-- C21 · solucionar · DECIDIR: cada hallazgo del asesor frente a la causa real, y qué se acepta (y qué no)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN tipo FORMAT A14
COLUMN mensaje FORMAT A100
SELECT f.type AS tipo, SUBSTR(REGEXP_REPLACE(f.message, '\s+', ' '), 1, 100) AS mensaje
  FROM dba_advisor_findings f WHERE f.task_name = 'T6_C21_STA' ORDER BY f.finding_id;
COLUMN accion FORMAT A100
SELECT SUBSTR(REGEXP_REPLACE(a.message, '\s+', ' '), 1, 100) AS accion
  FROM dba_advisor_actions a WHERE a.task_name = 'T6_C21_STA' AND a.message IS NOT NULL ORDER BY a.rec_id, a.action_id;
PROMPT == La decisión del DBA (se documenta en el ticket) ==
PROMPT   Índice sobre TO_NUMBER(codigo_postal) ... NO: tapa el defecto; cada nueva consulta con NUMBER necesitaría otro.
PROMPT   Perfil SQL (si lo propone) ............... NO: ajusta estimaciones, pero el filtro TO_NUMBER impide el índice igual.
PROMPT   Reescribir el SQL / tipo de dato ......... SÍ: es la causa. La V2 (VARCHAR2) ya lo resuelve: casos C07 y C17.
PROMPT   El asesor señala bien el SÍNTOMA; la CAUSA la confirma el DBA con el plan real y el código.
EXIT
