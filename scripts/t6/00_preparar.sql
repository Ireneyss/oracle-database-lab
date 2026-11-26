-- =====================================================================================================
-- 00_preparar.sql · Tema 6 / Laboratorio 7 · crea (o devuelve a su punto de partida) el banco T6
-- Qué hace : tablespace TBS_T6 y esquema T6 (sin contraseña) con una copia de TIENDASUR (Lab 5): T6.CLIENTE
--   (100 000 filas + COMUNIDAD, que depende de CIUDAD) y T6.PEDIDO (1 000 000). Estadísticas SIN histogramas
--   (el punto de partida «ingenuo»), la aplicación T6.APP (la tienda web), su telemetría T6.APP_LOG, el registro
--   de líneas base T6.LINEA_BASE y la cuenta de aplicación T6_APP. Borra lo que hayan dejado los casos:
--   líneas base de SPM, tareas de asesores, parámetros de la PDB cambiados, cursores en la shared pool.
-- Por qué   : los casos cambian estadísticas, índices y planes. Se hace en una copia para no tocar TIENDASUR.
-- Requisito: estado final del Lab 6 (o del Lab 5): esquema TIENDASUR en FREEPDB1.
-- Efectos   : unos 130 MB en TBS_T6 (NOLOGGING: la copia es desechable). 99_limpiar.sql lo borra todo.
-- Ejecutar  : caso --preparar          Errores esperados: ninguno
-- =====================================================================================================
@@_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF
WHENEVER SQLERROR EXIT FAILURE
PROMPT == 1 · Comprobaciones y limpieza de lo que dejaron los casos ==
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_users WHERE username = 'TIENDASUR';
  IF n = 0 THEN RAISE_APPLICATION_ERROR(-20600, 'Falta TIENDASUR (Lab 5, V004 y V005): sin ella no hay banco T6'); END IF;
  -- Líneas base de SPM, perfiles y tareas de los casos (no pertenecen al esquema: DROP USER no las borra)
  FOR b IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE sql_text LIKE '%t6%' OR sql_text LIKE '%T6.%') LOOP
    n := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => b.sql_handle);
  END LOOP;
  FOR p IN (SELECT name FROM dba_sql_profiles WHERE name LIKE 'T6%' OR sql_text LIKE '%t6.%') LOOP
    DBMS_SQLTUNE.DROP_SQL_PROFILE(p.name);
  END LOOP;
  FOR t IN (SELECT task_name FROM dba_advisor_tasks WHERE task_name LIKE 'T6%') LOOP
    BEGIN DBMS_SQLTUNE.DROP_TUNING_TASK(t.task_name); EXCEPTION WHEN OTHERS THEN DBMS_ADVISOR.DELETE_TASK(t.task_name); END;
  END LOOP;
  FOR u IN (SELECT username FROM dba_users WHERE username IN ('T6', 'T6_APP')) LOOP
    EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
  END LOOP;
  SELECT COUNT(*) INTO n FROM dba_tablespaces WHERE tablespace_name = 'TBS_T6';
  IF n > 0 THEN EXECUTE IMMEDIATE 'DROP TABLESPACE tbs_t6 INCLUDING CONTENTS AND DATAFILES'; END IF;
END;
/
-- Parámetros de la PDB que tocan los casos y los incidentes: vuelven a su valor heredado
BEGIN
  FOR p IN (SELECT name FROM v$system_parameter
             WHERE isdefault = 'FALSE' AND con_id = SYS_CONTEXT('USERENV', 'CON_ID')
               AND name IN ('optimizer_mode', 'optimizer_index_cost_adj', 'optimizer_features_enable', 'cursor_sharing',
                            'optimizer_use_invisible_indexes', 'optimizer_use_pending_statistics', 'pga_aggregate_target',
                            'optimizer_capture_sql_plan_baselines', 'optimizer_adaptive_plans', 'db_file_multiblock_read_count',
                            'statistics_level', 'optimizer_dynamic_sampling')) LOOP
    EXECUTE IMMEDIATE 'ALTER SYSTEM RESET ' || p.name || ' SCOPE = BOTH';
  END LOOP;
END;
/
WHENEVER SQLERROR CONTINUE
SET ECHO ON
PROMPT == 2 · El banco: copia de TiendaSur en el esquema T6 ==
CREATE TABLESPACE tbs_t6 DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tbs_t6_01.dbf'
  SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE 1G;
CREATE USER t6 NO AUTHENTICATION DEFAULT TABLESPACE tbs_t6 QUOTA UNLIMITED ON tbs_t6;
SET ECHO OFF
CREATE TABLE t6.cliente NOLOGGING TABLESPACE tbs_t6 AS
SELECT c.id_cliente, c.dni, c.email, c.nombre, c.apellidos, c.pais, c.ciudad,
       CASE WHEN c.ciudad = 'Lorca' THEN 'MURCIA'
            ELSE 'COM' || LPAD(MOD(TO_NUMBER(SUBSTR(c.ciudad, 7)), 17) + 1, 2, '0') END AS comunidad,
       c.fecha_alta
  FROM tiendasur.cliente c ORDER BY c.id_cliente;
CREATE TABLE t6.pedido NOLOGGING TABLESPACE tbs_t6 AS
SELECT id_pedido, id_cliente, fecha_pedido, estado, importe, canal, codigo_postal
  FROM tiendasur.pedido ORDER BY id_pedido;
ALTER TABLE t6.cliente ADD CONSTRAINT pk_t6_cliente PRIMARY KEY (id_cliente);
ALTER TABLE t6.pedido  ADD CONSTRAINT pk_t6_pedido  PRIMARY KEY (id_pedido);
ALTER TABLE t6.pedido  ADD CONSTRAINT fk_t6_ped_cli FOREIGN KEY (id_cliente) REFERENCES t6.cliente;
CREATE INDEX t6.ix_t6_ped_cliente ON t6.pedido (id_cliente);
CREATE INDEX t6.ix_t6_ped_fecha   ON t6.pedido (fecha_pedido);
CREATE INDEX t6.ix_t6_ped_estado  ON t6.pedido (estado);
CREATE INDEX t6.ix_t6_ped_cp      ON t6.pedido (codigo_postal);
CREATE INDEX t6.ix_t6_cli_ciudad  ON t6.cliente (ciudad);
CREATE INDEX t6.ix_t6_cli_email   ON t6.cliente (email);
-- Telemetría de la aplicación (latencia de cada llamada) y registro de líneas base del DBA
CREATE TABLE t6.app_log (ts TIMESTAMP DEFAULT SYSTIMESTAMP, etq VARCHAR2(20), ms NUMBER) TABLESPACE tbs_t6;
CREATE TABLE t6.linea_base (
  ts TIMESTAMP DEFAULT SYSTIMESTAMP, caso VARCHAR2(4), etiqueta VARCHAR2(30), sql_id VARCHAR2(13), plan_hash NUMBER,
  ejecuciones NUMBER, ms_ejec NUMBER, cpu_ms_ejec NUMBER, gets_ejec NUMBER, lect_fis_ejec NUMBER, filas_ejec NUMBER,
  nota VARCHAR2(200)) TABLESPACE tbs_t6;
PROMPT == 3 · La aplicación: el paquete T6.APP (la tienda web) ==
CREATE OR REPLACE PACKAGE t6.app AUTHID DEFINER AS
  PROCEDURE etiqueta(p VARCHAR2);                 -- etiqueta de la telemetría (la pone el generador de carga)
  PROCEDURE panel_ventas;                         -- C01 · panel en directo: recorre PEDIDO en memoria (solo CPU)
  PROCEDURE ficha_literal(p_id NUMBER);           -- C03 · la versión en producción: concatena el literal
  PROCEDURE ficha_bind(p_id NUMBER);              -- C03 · la corregida: variable de enlace
  PROCEDURE buscar_cp_v1(p_cp NUMBER);            -- INC-604 · en producción: el código postal llega como número
  PROCEDURE buscar_cp_v2(p_cp VARCHAR2);          -- INC-604 · corregida: el tipo coincide con el de la columna
END;
/
CREATE OR REPLACE PACKAGE BODY t6.app AS
  g_etq VARCHAR2(20) := 'SIN_ETQ';
  PROCEDURE etiqueta(p VARCHAR2) IS BEGIN g_etq := p; END;
  PROCEDURE anotar(p_t0 TIMESTAMP) IS
  BEGIN
    INSERT INTO t6.app_log (etq, ms)
    VALUES (g_etq, EXTRACT(SECOND FROM (SYSTIMESTAMP - p_t0)) * 1000 + EXTRACT(MINUTE FROM (SYSTIMESTAMP - p_t0)) * 60000);
  END;
  PROCEDURE panel_ventas IS t0 TIMESTAMP := SYSTIMESTAMP; n NUMBER;
  BEGIN
    SELECT /*+ t6_panel */ COUNT(*) INTO n FROM t6.pedido WHERE MOD(id_pedido * 7, 13) = 3;
    anotar(t0);
  END;
  PROCEDURE ficha_literal(p_id NUMBER) IS t0 TIMESTAMP := SYSTIMESTAMP; v_nom VARCHAR2(60); v_ciu VARCHAR2(40);
  BEGIN
    EXECUTE IMMEDIATE 'SELECT /* t6_ficha */ nombre, ciudad FROM t6.cliente WHERE id_cliente = ' || p_id INTO v_nom, v_ciu;
    anotar(t0);
  END;
  PROCEDURE ficha_bind(p_id NUMBER) IS t0 TIMESTAMP := SYSTIMESTAMP; v_nom VARCHAR2(60); v_ciu VARCHAR2(40);
  BEGIN
    EXECUTE IMMEDIATE 'SELECT /* t6_ficha */ nombre, ciudad FROM t6.cliente WHERE id_cliente = :id' INTO v_nom, v_ciu USING p_id;
    anotar(t0);
  END;
  PROCEDURE buscar_cp_v1(p_cp NUMBER) IS t0 TIMESTAMP := SYSTIMESTAMP; n NUMBER; s NUMBER;
  BEGIN
    SELECT /*+ t6_cp_v1 */ COUNT(*), SUM(importe) INTO n, s FROM t6.pedido WHERE codigo_postal = p_cp;
    anotar(t0);
  END;
  PROCEDURE buscar_cp_v2(p_cp VARCHAR2) IS t0 TIMESTAMP := SYSTIMESTAMP; n NUMBER; s NUMBER;
  BEGIN
    SELECT /*+ t6_cp_v2 */ COUNT(*), SUM(importe) INTO n, s FROM t6.pedido WHERE codigo_postal = p_cp;
    anotar(t0);
  END;
END;
/
SHOW ERRORS
PROMPT == 4 · La cuenta de la aplicación (T6_APP): ejecuta la tienda y puede ver sus propios planes ==
CREATE USER t6_app IDENTIFIED BY "&PWD_CASO" DEFAULT TABLESPACE tbs_t6;
GRANT CREATE SESSION TO t6_app;
GRANT EXECUTE ON t6.app TO t6_app;
GRANT SELECT ON t6.pedido TO t6_app;
GRANT SELECT ON t6.cliente TO t6_app;
GRANT SELECT ON sys.v_$session TO t6_app;
GRANT SELECT ON sys.v_$sql TO t6_app;
GRANT SELECT ON sys.v_$sql_plan TO t6_app;
GRANT SELECT ON sys.v_$sql_plan_statistics_all TO t6_app;
GRANT SELECT ON sys.v_$mystat TO t6_app;
GRANT SELECT ON sys.v_$statname TO t6_app;
GRANT SELECT ON sys.v_$parameter TO t6_app;
GRANT SELECT ON sys.v_$mystat TO t6;
GRANT SELECT ON sys.v_$statname TO t6;
-- El banco de medida del Lab 5 (LAB_TOOLS.MEDIR) también mide sobre T6 (privilegio de esquema, 23ai)
GRANT SELECT ANY TABLE ON SCHEMA t6 TO lab_tools;
PROMPT == 5 · Estadísticas «ingenuas» (sin histogramas) y una shared pool limpia ==
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS('T6', 'CLIENTE', method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS('T6', 'PEDIDO',  method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);
  -- SIZE 1 también para las recogidas futuras del mantenimiento automático: el banco no cambia solo de noche
  DBMS_STATS.SET_TABLE_PREFS('T6', 'PEDIDO',  'METHOD_OPT', 'FOR ALL COLUMNS SIZE 1');
  DBMS_STATS.SET_TABLE_PREFS('T6', 'CLIENTE', 'METHOD_OPT', 'FOR ALL COLUMNS SIZE 1');
END;
/
ALTER SYSTEM FLUSH SHARED_POOL;
SET ECHO OFF
PROMPT == 6 · Resultado ==
SELECT table_name, num_rows, blocks, last_analyzed FROM dba_tables WHERE owner = 'T6' ORDER BY table_name;
SELECT index_name, table_name, blevel, leaf_blocks, distinct_keys, clustering_factor
  FROM dba_indexes WHERE owner = 'T6' ORDER BY table_name, index_name;
SELECT CASE WHEN COUNT(*) = 2 THEN 'OK    ' ELSE 'FALLO ' END || 'Banco T6 listo: T6 y T6_APP creados' AS resultado
  FROM dba_users WHERE username IN ('T6', 'T6_APP');
EXIT
