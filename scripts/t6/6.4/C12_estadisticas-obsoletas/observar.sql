-- C12 · observar · ¿por qué no lo arregló la tarea automática? Cuándo actúa, con qué umbral, y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
COLUMN client_name FORMAT A32
COLUMN window_group FORMAT A16
COLUMN next_start_date FORMAT A17
COLUMN duration FORMAT A14
SELECT client_name, status, window_group FROM dba_autotask_client WHERE client_name LIKE '%stats%';
SELECT window_name, TO_CHAR(next_start_date, 'YYYY-MM-DD HH24:MI') AS next_start_date, duration
  FROM dba_scheduler_windows WHERE enabled = 'TRUE' ORDER BY next_start_date FETCH FIRST 2 ROWS ONLY;
SELECT 'STALE_PERCENT' AS preference_name, DBMS_STATS.GET_PREFS('STALE_PERCENT', 'T6', 'CARRITO') AS preference_value FROM dual;
PROMPT == Lo que debes retener ==
PROMPT 1. La tarea automática recoge en la ventana de mantenimiento (de noche): una carga a las 3:00 llega tarde.
PROMPT 2. El proceso que CARGA es el que recoge al terminar (GATHER_TABLE_STATS en el propio job): runbook RB-2.
PROMPT 3. Se diagnostica con pruebas, no con fe: STALE_STATS, DBA_TAB_MODIFICATIONS y E-Rows frente a A-Rows.
PROMPT 4. Tablas de trabajo que se vacían y se llenan: estadísticas representativas BLOQUEADAS (LOCK_TABLE_STATS), caso C13.
PROMPT 5. Variante: con optimizer_adaptive_plans = TRUE (el valor por defecto) el plan empieza en NESTED LOOPS y cambia a HASH
PROMPT    JOIN a mitad de la ejecución (caso C11). Eso tapa el síntoma del join, pero la estimación sigue equivocada: E-Rows 100.
PROMPT    Para recoger con red (pendientes, publicar, restaurar), el caso C13.
EXIT
