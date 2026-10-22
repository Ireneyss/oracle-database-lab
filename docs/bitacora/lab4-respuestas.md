# Lab 4 · Oracle DBA Workflow I — Respuestas

Rutas de evidencia relativas a `docs/bitacora/lab4/evidencia/`. Las horas son UTC (en la terminal local, +2 h).

## Diferencias de mi entorno respecto al enunciado

- **ARCHIVELOG.** Mi base está en `ARCHIVELOG` (evidencia 00, inventario: `log_mode=ARCHIVELOG`; `script/20261022T165926Z_06-arranque-por-etapas.script.log`), no en NOARCHIVELOG. Por eso aparecen 4 procesos `ARCn` (H) y 2 redo archivados (122 MB, J), y el volumen ocupa 4,8 GB en lugar de 3 GB. No hay FRA: `db_recovery_file_dest` está vacío.
- **`$ORACLE_HOME/dbs` es un enlace simbólico** a `/opt/oracle/oradata/dbconfig/FREE/dbs`, dentro del volumen. Por eso la copia de la Parte A no encontró archivos FUERA.
- **Números distintos** a los del enunciado: los datafiles de negocio son los file# 16–20 (no 25…), la fila 101 está en el bloque 783 (no 782) y la tabla `ACA_ESTUDIANTES` es el objeto 73124.

---

## Puntos de control y retos

### Parte A

**Punto de control — archivos FUERA del volumen.**
Salieron **0 archivos FUERA** (evidencia 00, paso 3). Los cinco datafiles de negocio (file# 16–20, evidencia 01) se crearon en `$ORACLE_HOME/dbs` porque V000 usó rutas relativas (`'academia01.dbf'`) y `db_create_file_dest` estaba vacío, así que Oracle tomó `$ORACLE_HOME/dbs` como carpeta base. En esta imagen `$ORACLE_HOME/dbs` es un enlace a `/opt/oracle/oradata/dbconfig/FREE/dbs`, de modo que están dentro del volumen y sobreviven a `docker rm`, pero en una carpeta no estándar que depende de un enlace que una actualización de imagen podría cambiar. La corrección (Parte C) es la misma: llevarlos a `FREE/FREEPDB1/`.

**Reto — informe de diagnóstico.**

| # | Hallazgo | Riesgo |
| --- | --- | --- |
| 1 | Contraseñas de los cinco `admin_*` en V000, en el historial de Git | Alto |
| 2 | `08-aplicar-migraciones.sh` pasa `sys/<contraseña>` en la línea de comandos (visible con `ps`) | Alto |
| 3 | Datafiles de negocio en `dbconfig/FREE/dbs`, carpeta no estándar que depende de un enlace | Medio |
| 4 | ARCHIVELOG sin FRA: los archivados crecen sin destino gestionado ni límite | Medio |
| 5 | Puerto 8181 publicado sin servicio detrás | Bajo |

Orden: primero 1 y 2, porque son credenciales ya expuestas y cada día que pasan es exposición; después 3, que protege los datos ante un cambio de imagen; luego 4, que puede llenar el disco; y al final 5, que solo es superficie de ataque sin servicio.

### Parte B

**Reto — mínimo privilegio.**
Dar el rol DBA a C##OPS_RO tiene al menos dos riesgos concretos: (1) la cuenta podría modificar o borrar cualquier objeto y crear usuarios o conceder privilegios, así que un despiste o un script con error se convierte en incidencia; (2) si su contraseña se filtra (está en `config/.env` y la usa una herramienta), el atacante obtiene control total de la base en lugar de solo lectura. Además, la auditoría pierde sentido: no se distingue quién mira de quién cambia.
Para leer el alert log basta con un único privilegio de objeto: `GRANT SELECT ON sys.v_$diag_alert_ext TO c##ops_ro CONTAINER = ALL;` (es lo que hace `11-ampliar-ops-ro.sql`, `script/20261022T171255Z_11-ampliar-ops-ro.script.log`).

### Parte C

**Reto — que no vuelva a pasar (OMF).**
Comando: `ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' SCOPE = BOTH;` (`scripts/lab4/03-reto-omf.sql`, `script/20261022T164937Z_03-reto-omf.script.log`).
`SCOPE = BOTH` porque el parámetro es dinámico (se aplica ya) y además debe quedar escrito en el SPFILE para sobrevivir a reinicios; en la Parte F se ve como `ISDEFAULT = FALSE` y en `v$spparameter`.
Efecto: un `CREATE TABLESPACE prueba_omf;` sin cláusula `DATAFILE` crea el archivo él solo dentro del volumen, con nombre gestionado por Oracle, en `/opt/oracle/oradata/FREE/<GUID de FREEPDB1>/datafile/o1_mf_….dbf` (la carpeta `55E54F210F100828E0630B00580ADFD0` que aparece en la evidencia 05; ese GUID también es un servicio del listener). Matiz observado en la Parte I: si se indica la ruta (por ejemplo, `FILE_NAME_CONVERT` al crear `PDB_LAB4`), esa ruta tiene prioridad sobre OMF.

### Parte E

**Punto de control — ORA-01507 y ORA-01219** (`script/20261022T165926Z_06-arranque-por-etapas.script.log`).
- En **NOMOUNT** la instancia ya existe (lee el SPFILE, reserva la SGA de 1 603 398 928 bytes y arranca procesos), por eso `v$parameter` responde. Pero `v$database` necesita el control file, que aún no se ha abierto: `ORA-01507: database not mounted`.
- En **MOUNT** ya se leyeron los control files: `v$database` responde (`MOUNTED`, `ARCHIVELOG`) y `v$datafile` conoce los 16 datafiles. Pero `dba_tables` es una vista del diccionario, que vive en el tablespace SYSTEM, un datafile todavía cerrado: `ORA-01219`. Solo funcionan las vistas fijas (V$/X$), que leen memoria y control file.
- En **OPEN** se abren datafiles y redo, y FREEPDB1 se abre sola por su estado guardado (`dba_pdb_saved_states`).

**Reto — el parte del reinicio** (alert log, `script/20261022T165945Z_06-alert-log.script.log`).
- Parada pedida: **16:59:26** UTC (`Shutting down ORACLE instance (immediate)`).
- Instancia arrancada: 16:59:30; base abierta (`Completed: ALTER DATABASE OPEN`): **16:59:35**. Duración total del reinicio: unos **9 segundos**, de los cuales 5 s entre arrancar la instancia y abrir la base.
- Recuperación de instancia: **no hubo**. La línea `Crash Recovery excluding pdb … cleanly closed` aparece, pero no hay `Beginning crash recovery` ni `Completed crash recovery`; la parada anterior fue `SHUTDOWN IMMEDIATE`.
- Errores:
  - `ORA-00800 [Set Priority Failed] [VKTM]/[LGWR]` → **conocido**: el contenedor no permite subir la prioridad de esos procesos (falta `CAP_SYS_NICE`); no afecta.
  - `ORA-07427/ORA-27300/ORA-27302 spstp: cannot change directory to dbs` → **conocido / histórico**: fechado el 2026-07-05, cuando se construyó la imagen (aún no existía el enlace `dbs`). No se repite en los arranques de hoy.
- Observación: el alert log tiene 255 líneas de julio, **0 de septiembre** y 78 de octubre. El historial del Lab 3 se perdió al recrear el contenedor en la Parte C porque el ADR (`/opt/oracle/diag`) no está en el volumen.

### Parte F

**Reto — petición de cambio: `open_cursors` a 1000 por ORA-01000.**
- **Valor actual y origen:** 300, escrito en el SPFILE (`*.open_cursors=300`, `ISDEFAULT = FALSE`; `spool/20261022T170136Z_07-parametros-lectura.spool.log`). Es dinámico (`IMMEDIATE`) y modificable por PDB.
- **Diagnóstico previo:** ORA-01000 suele indicar cursores que la aplicación no cierra. Antes de cambiar nada, medir los cursores abiertos por sesión (`v$sesstat` con la estadística `opened cursors current`, o `v$open_cursor`) y ver si crecen sin parar (fuga) o se estabilizan cerca del límite (uso legítimo).
- **Propuesta:** si es una fuga, corregir la aplicación y no tocar el parámetro. Si el uso es legítimo, subirlo solo en la PDB afectada: `ALTER SESSION SET CONTAINER = FREEPDB1; ALTER SYSTEM SET open_cursors = 1000 COMMENT = 'CR-xxx: ORA-01000 app' SCOPE = BOTH;`. `SCOPE = BOTH` para que se aplique ya y sobreviva al reinicio.
- **Prueba:** en el entorno de laboratorio primero; comprobar `v$parameter` y `v$spparameter` y repetir la carga que daba ORA-01000.
- **Rollback:** `ALTER SYSTEM SET open_cursors = 300 SCOPE = BOTH;` en la PDB (o `ALTER SYSTEM RESET open_cursors` para heredar el valor del CDB).
- **Evidencia:** valores antes y después de `v$parameter`/`v$spparameter`, copia del PFILE (`CREATE PFILE FROM SPFILE`) antes del cambio y salida de la prueba.

### Parte G

**Punto de control — experimento de caché** (`script/20261022T170310Z_08-experimento-cache.script.log`).
- Ronda 1 (caché fría): 355 lecturas lógicas y 259 físicas. Ronda 2 (caché caliente): 247 lógicas y 0 físicas.
- En mi caso las lógicas **no** son iguales (el enunciado dice que sí). La ronda 1 tiene 108 de más porque es la primera ejecución: incluye el análisis de la sentencia y las consultas recursivas al diccionario, que también cuentan como lecturas de la sesión.
- Las 259 físicas superan los 244 bloques de la tabla: son los 244 de datos, más la cabecera del segmento, más bloques del diccionario que no estaban en caché. Toda lectura física termina además en una lógica (el bloque se trae a la caché y se lee desde ahí).
- `v$bh` muestra 245 bloques en caché: 244 de datos y 1 de cabecera.
- Tasa de acierto: ronda 1, 1 − 259/355 ≈ **27 %**; ronda 2, 1 − 0/247 = **100 %**.

**Punto de control — PGA** (`script/20261022T170310Z_08-parse-y-pga.script.log`).
- Con PGA automática, ordenar 60 000 filas necesitaba 2675 KB (`KB_OPTIMO`): `OPTIMAL`, 0 KB en TEMP, 30 ms.
- Con 64 KB manuales: **6 PASSES**, 3072 KB escritos en TEMP y 330 ms, 11 veces más lento con una tabla pequeña.
- En el histograma de la instancia, las 2 `VARIAS_PASADAS` son las de mi experimento; en producción cualquier valor distinto de 0 sería una alarma. El *cache hit percentage* de la PGA bajó de 100 % a 81,4 % por la misma razón.
- `maximum PGA allocated` (465,4 MB) no llegó a superar `pga_aggregate_target` (512 MB) en mi caso, pero el objetivo no es un límite: el límite es `pga_aggregate_limit` (2 GB); al acercarse, Oracle cortaría sesiones con ORA-04036.

**Reto — literales** (`scripts/lab4/08-reto-literales.sql`, `spool/20261022T170413Z_08-reto-literales.spool.log`).
Una sola `force_matching_signature` (1863221789280198928) acumula **377 cursores con 377 ejecuciones** en `CON_ID 3` (FREEPDB1): un cursor nuevo por cada valor del literal, con un único ejemplo `SELECT /* lab4_literal */ COUNT(*) … WHERE estudiante_id = 1000`. Es la sentencia que la aplicación ejecuta con literales en lugar de variables de enlace.

### Parte H

**Reto — la sesión que más consume** (`scripts/lab4/09-reto-sesion.sql`, `spool/20261022T170924Z_09-reto-sesion.spool.log`).

| Dato | Valor |
| --- | --- |
| SID | 209 (serial# 14830) |
| Usuario / contenedor | SYS, `CON_ID 3` (FREEPDB1) |
| SPID en Linux | 2754 |
| PGA | 3,3 MB usada, 3,7 MB asignada |
| Consulta | `SELECT COUNT(*) FROM admin_academia.aca_matriculas a, admin_academia.aca_matriculas b WHERE a.matricula_id < 10000` |

Consulta usada: `v$session` unida a `v$process` por `paddr = addr` (SPID y PGA) y a `v$sql` por `sql_id` (texto), filtrando `type = 'USER'` y `status = 'ACTIVE'`, ordenada por `pga_used_mem`. Mejora: excluir la propia sesión de búsqueda (aparece la primera, SID 176) con `AND s.sid <> SYS_CONTEXT('USERENV','SID')`. Las filas sin usuario (SID 64 y 223) son los procesos de jobs J000 y J001.

### Parte I

**Punto de control** (`script/20261022T171135Z_10-que-ve-cada-usuario.script.log`).
- **CON_ID 0 en V$LOG:** los 3 grupos de redo tienen CON_ID 0 porque el redo es de toda la CDB, no de una PDB: todas las PDB escriben en el mismo redo.
- **C##LAB4_AUDITOR** ve 87 sesiones con CON_ID 0 y 1 con CON_ID 1, pero ninguna de FREEPDB1, porque es un usuario común sin `CONTAINER_DATA`. Lo cambiaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.
- **SELECT ANY TABLE:** el privilegio de esquema dejó leer solo `ADMIN_ACADEMIA` (las 20 000 filas), y `ADMIN_CLINICA` siguió devolviendo ORA-00942. `SELECT ANY TABLE` habría abierto las tablas de todos los esquemas de la PDB, incluido `ADMIN_CLINICA`.

**Reto — acceso de una auditora externa** (diseño, no ejecutado).
```sql
-- Local y en FREEPDB1: solo necesita esa PDB (un usuario local no existe en la raíz ni en otras PDB)
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER auditora_clinica IDENTIFIED BY "<contraseña robusta>" PASSWORD EXPIRE;
GRANT CREATE SESSION TO auditora_clinica;
-- Privilegio de esquema: lee todas las tablas de ADMIN_CLINICA y nada más; READ no permite SELECT ... FOR UPDATE
GRANT READ ANY TABLE ON SCHEMA admin_clinica TO auditora_clinica;
-- Último día
REVOKE READ ANY TABLE ON SCHEMA admin_clinica FROM auditora_clinica;
ALTER USER auditora_clinica ACCOUNT LOCK;   -- o DROP USER auditora_clinica; si no se va a reutilizar
```
Justificación con I.2: un usuario local en la PDB no ve nada fuera de ella (LAB4_ANALISTA no pudo saltar a la raíz: ORA-01031); el privilegio de esquema abre un esquema y no los demás (ADMIN_CLINICA cerrado para quien solo tenía ADMIN_ACADEMIA); y leer no es escribir (el UPDATE dio ORA-41900).

### Parte J

**Punto de control** (`spool/20261022T171258Z_11-archivos.spool.log`, `script/20261022T171259Z_11-archivos-so.script.log`).
- **Password file «relacionado»:** no guarda datos de la base, pero sin él nadie puede autenticarse como SYSDBA por red (`remote_login_passwordfile = EXCLUSIVE`; ahora solo contiene a SYS). Es imprescindible, pero no es la base.
- **Enlaces de `$ORACLE_HOME/dbs`:** la carpeta entera es un enlace a `/opt/oracle/oradata/dbconfig/FREE/dbs`, así que el SPFILE y el password file viven en el volumen. Se gana que sobreviven a recrear el contenedor y entran en la copia del volumen.
- **TEMP:** es el único tablespace que no se respalda: guarda datos temporales de sesiones (ordenaciones, tablas temporales) que no hay que recuperar, y Oracle puede recrear sus tempfiles vacíos.

**Reto — plan de copia.**
Copia en frío completa: datafiles 3954 MB + control files 36 MB + redo online 600 MB + SPFILE y password file (unos KB) ≈ **4590 MB** sin comprimir (la copia comprimida de la Parte A ocupó 510 MB). Con RMAN sobrarían: los redo online (600 MB; RMAN copia los archivados), los tempfiles (ya excluidos), los bloques nunca usados de los datafiles (RMAN solo copia bloques usados: los cinco `TBS_*` de 100 MB están casi vacíos) y la copia manual del control file (RMAN usa autobackup).

### Parte K

**Punto de control — volcado del bloque 783** (`config/20261022T171408Z_12-volcado-bloque.trc.txt`).
- `avsp = fseo − fsbo`: 0x427 − 0xc6 = 0x361, en decimal 1063 − 198 = **865 bytes libres**; coincide con `avsp` y con `tosp`.
- Fecha de registro de la fila 101 (columna 6, `78 7e 0a 16 11 33 19 …`): siglo 120 − 100 = 20, año 126 − 100 = 26, mes 10, día 22, hora 17 − 1 = 16, minuto 51 − 1 = 50, segundo 25 − 1 = 24 → **2026-10-22 16:50:24 UTC**, el momento en que apliqué V002. Los 4 bytes restantes son la fracción de segundo.
- **Un UPDATE de la fila 101** necesita una ranura de la ITL para su transacción. Al visitar el bloque, Oracle ve que la transacción de la ranura 0x01 (`Lck 90`) ya está confirmada y hace la limpieza diferida: pone a 0 su `Lck` y los bytes de bloqueo de esas filas. Después la nueva transacción ocupa una ranura (la 0x02, libre, o la 0x01 ya reutilizable) y solo la fila 101 queda bloqueada por ella (`Lck 1`). Se puede comprobar repitiendo el volcado del bloque tras un UPDATE sin confirmar.

**Reto — abrir otro bloque.** PENDIENTE.

---

## Preguntas de comprobación

**1.** La copia es consistente porque se tomó tras `SHUTDOWN IMMEDIATE` (evidencia 00, paso 4: *Database closed / dismounted / instance shut down*): el cierre limpio hace un checkpoint final, todos los datafiles quedan con el mismo SCN de checkpoint y no hace falta redo para abrirla. Con la base abierta, cada archivo se copiaría en un instante distinto con bloques a medio escribir: sería inconsistente y solo serviría con recuperación (ARCHIVELOG y RMAN).

**2.** `manifiesto.txt` dice qué es la copia: etiqueta `lab3-final`, fecha 20261022T163416Z, contenedor, volumen, imagen, commit de Git `7dee274`, tipo «copia en frío consistente» y 0 archivos fuera del volumen. `SHA256SUMS` guarda la huella de cada archivo para detectar corrupción o modificación (`sha256sum --check` dio OK a los cuatro). `restaurar-estado.sh` comprueba primero esas sumas y se detiene si alguna falla, y después exige escribir el nombre del volumen antes de borrar nada.

**3.** **RPO** (cuántos datos puedo perder): mi copia es del 2026-10-22 a las 16:34 UTC; si restaurara, perdería todo lo posterior (reubicación de datafiles, V003, V002, OMF…). **RTO** (cuánto tardo en volver a dar servicio): no lo he medido porque no he restaurado; la copia tardó unos 2 minutos (16:32:34 → 16:34:16) más ~10 s de arranque, y el enunciado indica alrededor de un minuto para restaurar. Lo mediré en el simulacro del Lab 5.

**4.** En `$ORACLE_HOME/dbs` (`/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf`, etc., evidencia 01), porque V000 usó rutas relativas y, sin destino por defecto, Oracle las resuelve desde esa carpeta. Lo habría evitado `DB_CREATE_FILE_DEST` apuntando al volumen (OMF), o rutas absolutas en V000.

**5.** Porque `RENAME DATAFILE` solo cambia la ruta guardada en el control file; no mueve el archivo. Si antes no se copia el archivo con el sistema operativo a la nueva ruta (con el tablespace OFFLINE), Oracle no lo encontrará al ponerlo ONLINE (ORA-01157).

**6.** V000 ya se aplicó en todos los entornos: una migración aplicada es historia, y editarla haría que entornos distintos tuvieran estados distintos con el «mismo» V000. Los cambios van en una migración nueva (V003). Borrar las contraseñas del archivo no sirve porque siguen en el historial de Git; invalidarlas sí protege: con `NO AUTHENTICATION`, la contraseña antigua `Academia_2026_*` da ORA-01017.

**7.** Demuestra que el contenedor es desechable y que todo el estado vive en el volumen: tras `docker rm` y recrear con el 05 v2, los 5 tablespaces y las 14 tablas de negocio son idénticos, y ya no se publica el 8181 (`script/…_03-prueba-persistencia.script.log`). Se ejecuta después de reubicar porque, si algún datafile estuviera en la capa del contenedor, el `docker rm` lo borraría; y después de la copia de la Parte A, por si algo sale mal.

**8.** Instancia (cambia al rearrancar o recrear): `STARTUP_TIME` 2026-10-22 16:47:01; `HOST_NAME` 8b68d5c7389b (el ID del contenedor nuevo; antes era 606c30eea60f); SGA de 1536 MB y 60 procesos de background. Base de datos (persiste en disco): `DBID` 1509902213; `CREATED` 2026-07-05; `LOG_MODE` ARCHIVELOG, con 16 datafiles, 2 control files y 3 redo (`spool/20261022T165318Z_05-instancia-y-base.spool.log`, `script/20261022T165741Z_05-instancia-so.script.log`).

**9.** NOMOUNT lee el SPFILE (o PFILE): reserva la SGA y arranca los procesos. MOUNT lee los control files: conoce datafiles y redo, pero no los abre. OPEN abre datafiles y redo online. Por eso en NOMOUNT `v$database` da ORA-01507 (no hay control file abierto) y en MOUNT `dba_tables` da ORA-01219 (el diccionario está en SYSTEM, todavía cerrado).

**10.** `v$parameter` es el valor efectivo en memoria; `v$spparameter`, lo escrito en el SPFILE. Con `db_files` (estático): `SCOPE = MEMORY` falló con ORA-02095; con `SCOPE = SPFILE` quedó 200 en memoria y 300 en el SPFILE, pendiente del próximo arranque; tras `RESET`, el SPFILE volvió a «no especificado» (`script/20261022T170137Z_07-parametros-cambios.script.log`).

**11.** Porque `PROCESSES` dimensiona estructuras de la SGA que se reservan al arrancar. Aunque `v$parameter` diga `ISSYS_MODIFIABLE = IMMEDIATE`, el cambio en memoria dio ORA-02097 + ORA-02095: en la práctica es estático. La metadata orienta; la prueba decide.

**12.** **ASMM** (gestión automática de la memoria compartida), no AMM: `memory_target = memory_size = 0`, `sga_target = 1536M` y `pga_aggregate_target = 512M`. Además, `db_cache_size` y `shared_pool_size` están a 0, así que Oracle reparte la SGA: buffer cache 1024 MB y shared pool 384 MB en `v$sga_dynamic_components` (`spool/20261022T170309Z_08-memoria.spool.log`).

**13.** Ver el punto de control de la Parte G: 355/259 en caché fría y 247/0 en caliente; tasa de acierto ≈ 27 % y 100 %; 245 bloques en `v$bh`.

**14.** Con literales, 1000 consultas provocaron 1092 análisis, de ellos 1008 duros, 660 ms de CPU y 690 ms en total. Con `:id`, 1 análisis (duro) y 10 ms. En `V$SQL` quedaron 414 cursores con literales ocupando 14 699 KB de shared pool, frente a 1 cursor con 1000 ejecuciones y 39 KB. Faltan unos 586 cursores porque la shared pool ya los había expulsado: eso también es coste (`script/20261022T170310Z_08-parse-y-pga.script.log`).

**15.** `v$process` da a LGWR el SPID **1421**, y dentro del contenedor `/proc/1421` es `db_lgwr_FREE` (igual con PMON 1373, DBW0 1419, CKPT 1423…; `script/20261022T171032Z_09-procesos-so.script.log`). `docker top` muestra otro número porque ve el proceso desde el anfitrión: el contenedor tiene su propio espacio de nombres de PID.

**16.** Desde la raíz, SYS ve los datafiles de los tres contenedores: 4 de `CDB$ROOT` + 3 de `PDB$SEED` + 9 de `FREEPDB1` = 16. Dentro de FREEPDB1, las V$ y las CDB_ se filtran a la propia PDB y solo ve sus 9 (`script/20261022T171135Z_10-que-ve-cada-usuario.script.log`).

**17.** Porque Oracle no revela la existencia de objetos que no puedes ver: responde como si no existieran (ORA-00942 en `DBA_TABLES`, `V$SESSION` y `ADMIN_ACADEMIA.ACA_ESTUDIANTES`). Cuando el objeto sí es visible pero falta una acción, 23ai sí lo dice: ORA-41900 *missing UPDATE privilege*.

**18.** Los dos son comunes, pero C##OPS_RO tiene el atributo `CONTAINER_DATA = ALL` (`DEFAULT_ATTR = Y`, `ALL_CONTAINERS = Y`) y desde la raíz ve las filas de todas las PDB; C##LAB4_AUDITOR solo ve la raíz y los datos con CON_ID 0. Los igualaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.

**19.** Ventaja: un solo `GRANT` cubre todas las tablas del esquema, también las que se creen después, sin mantener una lista tabla a tabla. Riesgo: precisamente eso; si mañana se crea en el esquema una tabla sensible, el usuario la puede leer sin que nadie lo haya decidido.

**20.** `COMMON_USER_PREFIX = C##`. Por eso, en el bloque 3a, `CREATE USER lab4_local` en la raíz falló con ORA-65096 (*common user or role name must start with prefix C##*): en la raíz solo se pueden crear usuarios comunes, y deben llevar el prefijo (`script/20261022T171142Z_10-ciclo-vida-pdb.script.log`).

**21.** **Son la base de datos:** 16 datafiles (3954 MB), 2 control files (36 MB), 3 redo online (600 MB) y 3 tempfiles (60 MB, que no se copian: se recrean). **Relacionados:** SPFILE, password file, el ADR (alert log y trazas) y los 2 redo archivados (122 MB). El password file va en «relacionados» porque no contiene datos de la base, aunque sin él nadie entra como SYSDBA por red.

**22.** 100 MB son 104 857 600 bytes; el archivo mide 104 865 792. La diferencia, 8192 bytes, es exactamente un bloque: el bloque de cabecera del archivo, que Oracle añade al tamaño pedido.

**23.** (1) Los 2 control files están en la misma carpeta y el mismo volumen (`/opt/oracle/oradata/FREE/`): si se pierde ese disco, se pierden los dos. (2) Cada grupo de redo tiene un solo miembro, sin multiplexar: si se corrompe el miembro del grupo actual, no hay copia.

**24.** Porque el alert log y las trazas son el historial de lo que le pasó a la base. Fuera del volumen (`/opt/oracle/diag`, apartado 4 de `11-archivos-so`), se pierden al recrear el contenedor: no se pueden investigar incidencias anteriores. Lo comprobé: tras recrear el contenedor en la Parte C, el alert log tenía 0 líneas de septiembre, todo el Lab 3 había desaparecido.

**25.** ROWID `AAAR2kAAAAAAAMPAAF`, formato OOOOOO FFF BBBBBB RRR en base 64 (A=0 … Z=25, a=26 … z=51, 0=52 … 9=61):

| Trozo | Caracteres | Cálculo | Valor | DBMS_ROWID |
| --- | --- | --- | --- | --- |
| Objeto | `AAAR2k` | 17·64² + 54·64 + 36 | 73124 | `DATA_OBJECT_ID` = 73124 (ACA_ESTUDIANTES) |
| Archivo | `AAA` | 0 | 0 | BIGFILE: archivo absoluto 16 con `ROWID_TO_ABSOLUTE_FNO` |
| Bloque | `AAAAMP` | 12·64 + 15 | 783 | `ROWID_BLOCK_NUMBER(rowid,'BIGFILE')` = 783 |
| Fila | `AAF` | 5 | 5 | `FILA_EN_BLOQUE` = 5 |

**26.** `nrow` = número de filas del bloque (90); `fsbo` = inicio del espacio libre (*free space begin offset*, justo después del directorio de filas: 0xc6); `fseo` = fin del espacio libre (*free space end offset*, donde empiezan las filas, que crecen desde el final: 0x427); `avsp` = espacio disponible. 0x427 − 0xc6 = 0x361 → 1063 − 198 = **865** = `avsp`.

**27.** La ranura 0x01 de la ITL tiene la transacción que insertó las 90 filas del bloque (V002). `Flag --U-` indica que ya hizo commit (*upper bound commit*, confirmado rápido), pero `Lck 90` indica que los bytes de bloqueo de esas 90 filas no se han limpiado. Es la **limpieza diferida de bloques**: el COMMIT no vuelve a visitar todos los bloques que modificó (por eso es rápido); el siguiente proceso que lea o modifique el bloque comprueba que la transacción terminó y limpia la ITL y los bytes de bloqueo.

**28.** `tl: 78` = 3 bytes de cabecera de fila (flag, byte de bloqueo y número de columnas, `cc: 7`) + 7 bytes de longitud (uno por columna, todas de menos de 250 bytes) + 68 bytes de datos (3 + 9 + 9 + 11 + 19 + 6 + 11). 3 + 7 + 68 = 78. Los 68 coinciden con `BYTES_DE_DATOS_FILA_101`.

---

## Preguntas tipo examen

PENDIENTE.
