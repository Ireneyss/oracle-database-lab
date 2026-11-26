-- C21 · observar · el otro asesor (SQL Access Advisor) propone ESTRUCTURAS; y lo que debes retener
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN
  DBMS_ADVISOR.QUICK_TUNE(DBMS_ADVISOR.SQLACCESS_ADVISOR, 'T6_C21_SAA',
    'SELECT canal, SUM(importe) FROM t6.pedido WHERE canal = ''T'' AND importe > 500 GROUP BY canal');
END;
/
COLUMN type FORMAT A12
SELECT rec_id, type, benefit, rank FROM dba_advisor_recommendations WHERE task_name = 'T6_C21_SAA' ORDER BY rank;
SET PAGESIZE 0 LONG 100000
SELECT DBMS_ADVISOR.GET_TASK_SCRIPT('T6_C21_SAA') FROM dual;
SET PAGESIZE 100
BEGIN DBMS_ADVISOR.DELETE_TASK('T6_C21_SAA'); DBMS_SQLTUNE.DROP_TUNING_TASK('T6_C21_STA'); END;
/
PROMPT == Lo que debes retener ==
PROMPT 1. SQL Tuning Advisor analiza UNA sentencia (estadísticas, rutas, estructura, perfil) y propone; el DBA decide.
PROMPT 2. SQL Access Advisor mira una carga y propone índices o vistas materializadas, con su guion: no lo ejecuta.
PROMPT 3. Aceptar un perfil o un índice sin entender la causa es tapar un síntoma: se valida con el plan real y la medida.
PROMPT 4. Requieren Tuning Pack en Enterprise Edition (CONTROL_MANAGEMENT_PACK_ACCESS); en Free están disponibles.
EXIT
