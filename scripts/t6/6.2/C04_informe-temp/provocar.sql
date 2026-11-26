-- C04 · provocar · el «ranking de pedidos por importe» de la herramienta de informes (cuenta T6_INF)
-- La cuenta de informes arrastra un disparador de inicio de sesión de una versión antigua de la herramienta (de cuando
-- no existía la PGA automática): pone WORKAREA_SIZE_POLICY = MANUAL y SORT_AREA_SIZE = 1 MB en cada sesión.
-- Efectos: cuenta T6_INF, disparador T6.C04_LEGADO, tabla T6.C04_MEDIDA. Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
BEGIN
  FOR u IN (SELECT 1 FROM dba_users WHERE username = 'T6_INF') LOOP EXECUTE IMMEDIATE 'DROP USER t6_inf CASCADE'; END LOOP;
  FOR t IN (SELECT 1 FROM dba_tables WHERE owner = 'T6' AND table_name = 'C04_MEDIDA') LOOP EXECUTE IMMEDIATE 'DROP TABLE t6.c04_medida PURGE'; END LOOP;
END;
/
CREATE USER t6_inf IDENTIFIED BY "&PWD_CASO" DEFAULT TABLESPACE tbs_t6;
GRANT CREATE SESSION TO t6_inf;
GRANT SELECT ON t6.pedido TO t6_inf;
GRANT SELECT ON sys.v_$mystat TO t6_inf;
GRANT SELECT ON sys.v_$statname TO t6_inf;
GRANT SELECT ON sys.v_$parameter TO t6_inf;
CREATE TABLE t6.c04_medida (modo VARCHAR2(14), filas NUMBER, ms NUMBER, temp_escritos NUMBER, temp_leidos NUMBER, politica VARCHAR2(10)) TABLESPACE tbs_t6;
GRANT INSERT ON t6.c04_medida TO t6_inf;
SET ECHO ON
CREATE OR REPLACE TRIGGER t6.c04_legado AFTER LOGON ON t6_inf.SCHEMA
BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET workarea_size_policy = MANUAL';
  EXECUTE IMMEDIATE 'ALTER SESSION SET sort_area_size = 1048576';
END;
/
SET ECHO OFF
PROMPT == El ranking de 1 000 000 de pedidos por importe, como lo lanza la herramienta de informes ... ==
@@_informe LEGADO COMPLETO
SELECT modo, filas, ms, temp_escritos, temp_leidos, politica FROM t6.c04_medida;
EXIT
