-- C15 · _medir · carga 100 000 pedidos (tres veces, la mejor) en T6.C15_CARGA y anota tiempo y redo con la etiqueta &1
SET ECHO OFF FEEDBACK OFF SERVEROUTPUT ON VERIFY OFF
DECLARE
  t0 NUMBER; g0 NUMBER; g1 NUMBER; t1 NUMBER; nix NUMBER;
  FUNCTION redo RETURN NUMBER IS v NUMBER;
  BEGIN SELECT m.value INTO v FROM v$mystat m JOIN v$statname n ON n.statistic# = m.statistic# WHERE n.name = 'redo size'; RETURN v; END;
BEGIN
  SELECT COUNT(*) INTO nix FROM dba_indexes WHERE owner = 'T6' AND table_name = 'C15_CARGA';
  t1 := 1E9;
  FOR vuelta IN 1 .. 3 LOOP   -- tres cargas, se queda la mejor: el tiempo de una sola es ruidoso
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t6.c15_carga';
    g0 := redo; t0 := DBMS_UTILITY.GET_TIME;
    INSERT INTO t6.c15_carga SELECT * FROM t6.pedido WHERE id_pedido <= 100000;
    COMMIT;
    t1 := LEAST(t1, (DBMS_UTILITY.GET_TIME - t0) * 10); g1 := redo - g0;
  END LOOP;
  INSERT INTO t6.c15_medida VALUES ('&1', nix, t1, ROUND(g1 / 1048576, 1));
  COMMIT;
  DBMS_OUTPUT.PUT_LINE(RPAD('&1', 14) || ' índices=' || nix || '   ' || t1 || ' ms   redo ' || ROUND(g1 / 1048576, 1) || ' MB');
END;
/
