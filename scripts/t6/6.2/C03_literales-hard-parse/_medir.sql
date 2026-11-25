-- C03 · _medir.sql (provocar, solucionar y observar) · 5 000 fichas de cliente con la versión &1 de la aplicación
-- &1 = LITERAL | BIND | FORCE (literal con CURSOR_SHARING = FORCE en la sesión). Mide la propia sesión (V$MYSTAT).
SET SERVEROUTPUT ON
DECLARE
  h0 NUMBER; p0 NUMBER; c0 NUMBER; t0 PLS_INTEGER; h NUMBER; p NUMBER; c NUMBER; ms NUMBER; k NUMBER;
  FUNCTION est(n VARCHAR2) RETURN NUMBER IS v NUMBER;
  BEGIN SELECT m.value INTO v FROM v$mystat m JOIN v$statname s ON s.statistic# = m.statistic# WHERE s.name = n; RETURN v; END;
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('tienda_web', 'C03_&1');
  h0 := est('parse count (hard)'); p0 := est('parse time elapsed'); c0 := est('CPU used by this session'); t0 := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. 5000 LOOP
    IF '&1' = 'BIND' THEN t6.app.ficha_bind(MOD(i * 37, 100000) + 1); ELSE t6.app.ficha_literal(MOD(i * 37, 100000) + 1); END IF;
  END LOOP;
  ms := (DBMS_UTILITY.GET_TIME - t0) * 10; h := est('parse count (hard)') - h0; p := (est('parse time elapsed') - p0) * 10;
  c := (est('CPU used by this session') - c0) * 10;
  SELECT COUNT(*) INTO k FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_ficha */%';
  DELETE FROM t6.c03_medida WHERE modo = '&1';
  INSERT INTO t6.c03_medida VALUES ('&1', 5000, ms, c, p, h, k);
  COMMIT;
END;
/
