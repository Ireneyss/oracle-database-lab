-- C14 · observar · el índice nuevo no sale gratis: cuánto cuesta escribir con él, y la marcha atrás sin borrar nada
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT ON
DECLARE
  g0 NUMBER; sin_ix NUMBER; invis NUMBER; vis NUMBER;
  FUNCTION redo RETURN NUMBER IS v NUMBER;
  BEGIN SELECT m.value INTO v FROM v$mystat m JOIN v$statname n ON n.statistic# = m.statistic# WHERE n.name = 'redo size'; RETURN v; END;
  PROCEDURE cambio IS BEGIN UPDATE t6.pedido SET canal = DECODE(canal, 'W', 'A', 'A', 'W', canal) WHERE id_pedido <= 20000; ROLLBACK; END;
BEGIN
  -- 1) sin mantenimiento: el índice UNUSABLE no se toca en las escrituras (skip_unusable_indexes = TRUE)
  EXECUTE IMMEDIATE 'ALTER INDEX t6.ix_t6_c14_pend UNUSABLE';
  g0 := redo; cambio; sin_ix := redo - g0;
  EXECUTE IMMEDIATE 'ALTER INDEX t6.ix_t6_c14_pend REBUILD ONLINE';
  cambio;   -- una pasada de calentamiento tras reconstruir
  -- 2) invisible y 3) visible
  EXECUTE IMMEDIATE 'ALTER INDEX t6.ix_t6_c14_pend INVISIBLE';
  g0 := redo; cambio; invis := redo - g0;
  EXECUTE IMMEDIATE 'ALTER INDEX t6.ix_t6_c14_pend VISIBLE';
  g0 := redo; cambio; vis := redo - g0;
  DBMS_OUTPUT.PUT_LINE('Redo de cambiar el canal de 20 000 pedidos: sin mantener el índice ' || ROUND(sin_ix / 1024)
     || ' KB · índice INVISIBLE ' || ROUND(invis / 1024) || ' KB · índice VISIBLE ' || ROUND(vis / 1024) || ' KB');
END;
/
SELECT index_name, visibility, status FROM dba_indexes WHERE owner = 'T6' AND index_name = 'IX_T6_C14_PEND';
PROMPT == Lo que debes retener ==
PROMPT 1. INVISIBLE cuesta lo mismo que VISIBLE al escribir: el optimizador no lo usa, pero cada DML lo mantiene (caso C15).
PROMPT 2. La prueba se hace con optimizer_use_invisible_indexes = TRUE en UNA sesión: nadie más cambia de plan.
PROMPT 3. Marcha atrás inmediata y sin reconstruir: ALTER INDEX ... INVISIBLE. Borrar es la última decisión.
PROMPT 4. Orden de columnas: primero las de igualdad (estado, canal) y después la de rango (fecha_pedido).
PROMPT 5. Variante de examen: un índice que se va a borrar se pone antes INVISIBLE una semana y se vigila DBA_INDEX_USAGE
PROMPT    (t6 indices PEDIDO). Runbook RB-3.
EXIT
