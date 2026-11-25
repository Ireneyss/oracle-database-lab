-- _registro.sql · apunta en T6.INC_REGISTRO quién rompió qué y con qué semilla (lo lee verificar)
-- Uso: @@../_registro INC-6NN SEMILLA ALUMNO DETALLE
SET ECHO OFF FEEDBACK OFF VERIFY OFF
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_tables WHERE owner = 'T6' AND table_name = 'INC_REGISTRO';
  IF n = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE t6.inc_registro (inc VARCHAR2(8), alumno VARCHAR2(4), semilla NUMBER, detalle VARCHAR2(200), roto TIMESTAMP) TABLESPACE tbs_t6';
  END IF;
  EXECUTE IMMEDIATE 'DELETE FROM t6.inc_registro WHERE inc = :1' USING '&1';
  EXECUTE IMMEDIATE 'INSERT INTO t6.inc_registro VALUES (:1, :2, :3, :4, SYSTIMESTAMP)' USING '&1', '&3', &2, '&4';
  COMMIT;
END;
/
