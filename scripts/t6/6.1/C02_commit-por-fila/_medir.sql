-- C02 · _medir.sql (lo usan provocar y solucionar) · inserta 20 000 ventas con COMMIT cada &1 filas y mide la sesión
-- &1 = filas por COMMIT (COMMIT WRITE WAIT: como lo hace una aplicación cliente) · &2 = etiqueta. Lee de V$MYSTAT y V$SESSION_EVENT de la PROPIA sesión, antes y después.
SET SERVEROUTPUT ON
DECLARE
  t0 PLS_INTEGER; c0 NUMBER; r0 NUMBER; w0 NUMBER; tw0 NUMBER; cpu0 NUMBER;
  FUNCTION est(p VARCHAR2) RETURN NUMBER IS v NUMBER;
  BEGIN SELECT m.value INTO v FROM v$mystat m JOIN v$statname s ON s.statistic# = m.statistic# WHERE s.name = p; RETURN v; END;
  PROCEDURE ev(n OUT NUMBER, t OUT NUMBER) IS
  BEGIN SELECT NVL(SUM(total_waits), 0), NVL(SUM(time_waited_micro), 0) INTO n, t FROM v$session_event
         WHERE sid = SYS_CONTEXT('USERENV', 'SID') AND event = 'log file sync'; END;
BEGIN
  DELETE FROM t6.venta_log WHERE etq = '&2'; COMMIT;
  c0 := est('user commits'); r0 := est('redo size'); cpu0 := est('CPU used by this session'); ev(w0, tw0);
  t0 := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. 20000 LOOP
    INSERT INTO t6.venta_log (etq, id_pedido, importe) VALUES ('&2', i, MOD(i, 500) + 0.99);
    -- Una aplicación (Java, Python...) que confirma desde el cliente ESPERA a LGWR en cada COMMIT. Dentro de un bucle
    -- PL/SQL, Oracle optimiza los COMMIT y no espera hasta el final: WRITE WAIT reproduce el comportamiento del cliente.
    IF MOD(i, &1) = 0 THEN COMMIT WRITE WAIT; END IF;
  END LOOP;
  COMMIT;
  DECLARE w1 NUMBER; tw1 NUMBER; ms NUMBER := (DBMS_UTILITY.GET_TIME - t0) * 10;
          c NUMBER := est('user commits') - c0; r NUMBER := est('redo size') - r0; cp NUMBER := (est('CPU used by this session') - cpu0) * 10;
  BEGIN
    ev(w1, tw1);
    INSERT INTO t6.c02_medida VALUES ('&2', &1, ms, c, r, cp, w1 - w0, ROUND((tw1 - tw0) / 1000));
  END;
  COMMIT;
END;
/
