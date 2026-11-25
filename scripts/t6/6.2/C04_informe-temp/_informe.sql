-- C04 · _informe.sql · ejecuta el informe como T6_INF y mide la sesión: &1 = etiqueta, &2 = COMPLETO | TOP100
-- Abre el cursor y trae TODAS las filas, como hace la herramienta de informes. Mide TEMP con V$MYSTAT.
CONNECT t6_inf/"&PWD_CASO"@//localhost:1521/freepdb1
SET SERVEROUTPUT ON
DECLARE
  TYPE t IS TABLE OF t6.pedido%ROWTYPE; c SYS_REFCURSOR; v t; n NUMBER := 0; t0 PLS_INTEGER; w0 NUMBER; r0 NUMBER;
  FUNCTION est(p VARCHAR2) RETURN NUMBER IS x NUMBER;
  BEGIN SELECT m.value INTO x FROM sys.v_$mystat m JOIN sys.v_$statname s ON s.statistic# = m.statistic# WHERE s.name = p; RETURN x; END;
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('informes', '&1');
  w0 := est('physical writes direct temporary tablespace'); r0 := est('physical reads direct temporary tablespace');
  t0 := DBMS_UTILITY.GET_TIME;
  IF '&2' = 'TOP100' THEN
    OPEN c FOR SELECT /*+ t6_informe_top100 */ * FROM t6.pedido ORDER BY importe DESC FETCH FIRST 100 ROWS ONLY;
  ELSE
    OPEN c FOR SELECT /*+ t6_informe_completo */ * FROM t6.pedido ORDER BY importe DESC;
  END IF;
  LOOP FETCH c BULK COLLECT INTO v LIMIT 5000; n := n + v.COUNT; EXIT WHEN v.COUNT < 5000; END LOOP;
  CLOSE c;
  DECLARE ms NUMBER := (DBMS_UTILITY.GET_TIME - t0) * 10; w NUMBER := est('physical writes direct temporary tablespace') - w0;
          r NUMBER := est('physical reads direct temporary tablespace') - r0; pol VARCHAR2(10);
  BEGIN
    SELECT value INTO pol FROM sys.v_$parameter WHERE name = 'workarea_size_policy';
    INSERT INTO t6.c04_medida VALUES ('&1', n, ms, w, r, pol);
  END;
  COMMIT;
END;
/
CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER = FREEPDB1;
